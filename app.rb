# frozen_string_literal: true
require 'bundler'
Bundler.require
Dotenv.load

require 'active_support/core_ext'

require_relative './lib/cleaned_output'
require_relative './lib/external_command'

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
    country, legislature = Everypolitician.country_legislature(
      country_slug,
      legislature_slug
    )

    branch = [country_slug, legislature_slug, Time.now.to_i].join('-').parameterize

    build_command = ExternalCommand.new(
      command: "#{File.join(__dir__, 'bin/everypolitician-data-builder')} 2>&1",
      env:     {
        'BRANCH_NAME'           => branch,
        'GIT_CLONE_URL'         => clone_url.to_s,
        'LEGISLATURE_DIRECTORY' => File.dirname(legislature.popolo),
        'SOURCE_NAME'           => source,
        'COUNTRY_NAME'          => country.name,
        'COUNTRY_SLUG'          => country.slug,
      }
    ).run

    cleaned_output = CleanedOutput.new(output: build_command.output, redactions: [ENV['MORPH_API_KEY']])

    unless build_command.success?
      Rollbar.error("Failed to build #{country.name} - #{legislature.name}\n\n#{cleaned_output}")
      return
    end
    title = "#{country.name} (#{legislature.name}): refresh data"
    body = "Automated data refresh for #{country.name} - #{legislature.name}" \
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
end

class CreatePullRequestJob
  class Error < StandardError; end

  include Sidekiq::Worker

  # Only retry 3 times, then discard the job
  sidekiq_options retry: 3, dead: false, queue: 'pull_requests'

  def perform(branch, title, body_key)
    # The branch won't exist if there were no changes when the rebuild was run.
    unless branch_exists?(branch)
      warn "Couldn't find branch: #{branch}"
      return
    end
    changes = github.compare(EVERYPOLITICIAN_DATA_REPO, 'master', branch)
    changed_files = changes[:files].map { |f| File.basename(f[:filename]) }
    unless changed_files.include?('ep-popolo-v1.0.json')
      warn 'No change to ep-popolo-v1.0.json detected, skipping'
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
  countries = Everypolitician::CountriesJson.new
  countries.each do |country|
    country[:legislatures].each do |legislature|
      if File.dirname(legislature[:popolo]) == "data/#{country_path}/#{legislature_path}"
        return rebuild(country[:slug], legislature[:slug])
      end
    end
  end
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
