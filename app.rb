# frozen_string_literal: true
require 'bundler'
Bundler.require
Dotenv.load

require 'active_support/core_ext'
require 'English'

require_relative './lib/cleaned_output'

configure :production do
  require 'rollbar/middleware/sinatra'

  use Rollbar::Middleware::Sinatra

  Rollbar.configure do |config|
    config.access_token = ENV['ROLLBAR_ACCESS_TOKEN']
    config.disable_monkey_patch = true
    config.environment = settings.environment
    config.framework = "Sinatra: #{Sinatra::VERSION}"
    config.root = Dir.pwd
  end
end

def github
  @github ||= Octokit::Client.new(
    access_token: github_access_token
  )
end

def github_access_token
  @github_access_token ||= ENV.fetch('GITHUB_ACCESS_TOKEN')
rescue KeyError
  abort 'Please set GITHUB_ACCESS_TOKEN in the environment before running'
end

EVERYPOLITICIAN_DATA_REPO = ENV.fetch(
  'EVERYPOLITICIAN_DATA_REPO',
  'everypolitician/everypolitician-data'
)

# Rebuild a given country's legislature information
class RebuilderJob
  include Sidekiq::Worker

  def perform(country_slug, legislature_slug, source = nil)
    country = EveryPolitician.country(country_slug)
    legislature = country.legislature(legislature_slug)

    if source
      src = EveryPolitician::Instructions.new(legislature).source(source)
      if src.current_data == src.fresh_data
        logger.warn "No morph changes for #{country_slug}/#{legislature_slug}/#{source}"
        return
      end
    end

    branch = [country_slug, legislature_slug, Time.now.to_i].join('-').parameterize

    output, child_status = run(
      "#{File.join(__dir__, 'bin/everypolitician-data-builder')} 2>&1",
      'BRANCH_NAME'           => branch,
      'GIT_CLONE_URL'         => clone_url.to_s,
      'LEGISLATURE_DIRECTORY' => 'data/' + legislature.directory,
      'SOURCE_NAME'           => source,
      'COUNTRY_NAME'          => country.name,
      'COUNTRY_SLUG'          => country.slug
    )

    cleaned_output = CleanedOutput.new(output: output, redactions: [ENV['MORPH_API_KEY']])

    unless child_status && child_status.success?
      Rollbar.error("Failed to build #{country.name} - #{legislature.name}\n\n#{cleaned_output}")
      return
    end
    source_name_with_default = source || 'all sources'
    title = "#{country.name} (#{legislature.name}): refresh #{source_name_with_default}"
    body = "Automated refresh of #{source_name_with_default} for #{country.name} - #{legislature.name}" \
      "\n\n#### Output\n\n```\n#{cleaned_output}\n```"
    Sidekiq.redis do |conn|
      key = "body:#{branch}"
      conn.set(key, body)
      conn.expire(key, 6.hours)

      # Wait so the branch is available through GitHub's API.
      # If the job executes immediately then the branch may not
      # be visible yet.
      CreatePullRequestJob.perform_in(1.minute, branch, title, key)
    end
  end

  private

  def clone_url
    @clone_url ||= URI.parse(repo.clone_url).tap do |repo_clone_url|
      repo_clone_url.user = github.login
      repo_clone_url.password = github.access_token
    end
  end

  def repo
    @repo ||= github.repository(EVERYPOLITICIAN_DATA_REPO)
  end

  # Unset bundler environment variables so it uses the correct Gemfile etc.
  def env
    @env ||= {
      'BUNDLE_GEMFILE'                => nil,
      'BUNDLE_BIN_PATH'               => nil,
      'RUBYOPT'                       => nil,
      'RUBYLIB'                       => nil,
      'NOKOGIRI_USE_SYSTEM_LIBRARIES' => '1',
    }
  end

  def run(command, extra_env = {})
    with_tmp_dir do
      output = IO.popen(env.merge(extra_env), command, &:read)
      [output, $CHILD_STATUS]
    end
  end

  def with_tmp_dir(&block)
    Dir.mktmpdir do |tmp_dir|
      Dir.chdir(tmp_dir, &block)
    end
  end
end

class CreatePullRequestJob
  class Error < StandardError; end

  include Sidekiq::Worker

  # Only retry 3 times, then discard the job
  sidekiq_options retry: 3, dead: false, queue: 'pull_requests'

  # If any of these change, then we have a usable build
  EXPECTED_FILES = ['ep-popolo-v1.0.json', 'unstable/positions.csv'].freeze

  def perform(branch, title, body_key)
    # The branch won't exist if there were no changes when the rebuild was run.
    unless branch_exists?(branch)
      warn "Couldn't find branch: #{branch}"
      return
    end
    changes = github.compare(EVERYPOLITICIAN_DATA_REPO, 'master', branch)
    changed_files = changes[:files].map { |f| f[:filename].split('/').drop(3).join('/') }
    unless (changed_files & EXPECTED_FILES).any?
      warn 'No usable change detected, skipping'
      return
    end
    body = Sidekiq.redis { |conn| conn.get(body_key) }
    body ||= 'Output of build no longer available'
    github.create_pull_request(
      EVERYPOLITICIAN_DATA_REPO,
      'master',
      branch,
      title,
      body
    )
  end

  def branch_exists?(branch_name)
    github.branch(EVERYPOLITICIAN_DATA_REPO, branch_name)
    true
  rescue Octokit::NotFound
    false
  end
end

module EveryPolitician
  class Instructions
    require 'json5'

    def initialize(legislature)
      @legislature = legislature
    end

    def source(name)
      Source.new(legislature: legislature, stanza: instructions[:sources].find { |src| src[:file].include? name })
    end

    private

    attr_reader :legislature

    def instructions_url
      legislature.popolo_url.sub('ep-popolo-v1.0.json', 'sources/instructions.json')
    end

    def raw_instructions
      @raw ||= open(instructions_url).read
    end

    def instructions
      JSON.parse(JSON5.parse(raw_instructions).to_json, symbolize_names: true)
    end
  end

  class Source
    GITHUB = 'https://raw.githubusercontent.com/everypolitician/everypolitician-data/master/data/%s/sources/%s'

    def initialize(stanza:, legislature:)
      @stanza = stanza
      @legislature = legislature
    end

    # TODO: handle all the other types of source
    def fresh_data
      return '' unless creation[:from] == 'morph'
      @fresh ||= MorphData.new(creation[:scraper]).query(creation[:query])
    end

    def current_data
      @current ||= open(GITHUB % [legislature.directory, stanza[:file]]).read
    end

    private

    attr_reader :stanza, :legislature

    def creation
      stanza[:create]
    end
  end
end

class MorphData
  require 'rest-client'

  def initialize(scraper)
    @scraper = scraper
  end

  def query(query)
    morph_api_url = 'https://api.morph.io/%s/data.csv' % scraper
    morph_api_key = ENV['MORPH_API_KEY']
    result = RestClient.get morph_api_url, params: {
      key:   morph_api_key,
      query: query,
    }
    result.to_s
  end

  private

  attr_reader :scraper
end

helpers do
  def rebuild(country, legislature, source = nil)
    RebuilderJob.perform_async(country, legislature, source)
    message = "Queued rebuild for country=#{country} legislature=#{legislature} source=#{source}\n"
    logger.warn(message)
    message
  end
end

get '/' do
  erb :bot_image
end

post '/:country/:legislature' do |country_path, legislature_path|
  logger.warn "Legacy route used: /#{country_path}/#{legislature_path}. Please use / with params"
  legislature = EveryPolitician.countries.flat_map(&:legislatures).find do |l|
    l.directory == "#{country_path}/#{legislature_path}"
  end
  rebuild(legislature.country.slug, legislature.slug)
end

post '/' do
  country = params[:country]
  legislature = params[:legislature]
  source = params[:source]
  rebuild(country, legislature, source)
end

post '/rebuild/:country_slug/:legislature_slug/?:source_name?' do |country_slug, legislature_slug, source_name|
  rebuild(country_slug, legislature_slug, source_name)
end
