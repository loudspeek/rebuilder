require 'bundler'
Bundler.require
Dotenv.load

require 'active_support/core_ext'
require 'English'

# Rebuild a given country's legislature information
class RebuilderJob
  include Sidekiq::Worker
  include Everypoliticianbot::Github

  def perform(country_slug, legislature_slug)
    branch_parts = [country_slug, legislature_slug, Time.now.to_i]
    branch = branch_parts.join('-').parameterize
    message = "#{country_slug}: Refresh from upstream changes"
    options = { branch: branch, message: message }
    output = nil
    with_git_repo(everypolitician_data_repo, options) do
      run('bundle install')
      Dir.chdir(File.join('data', country_slug, legislature_slug)) do
        output = run('bundle exec rake clobber default 2>&1')
      end
    end
    if branch_exists?(branch)
      api_key = ERB::Util.url_encode(ENV['MORPH_API_KEY'])
      output = output.gsub(api_key, 'REDACTED')
      body = "Automated data refresh for #{country_slug} - #{legislature_slug}" \
        "\n\n#### Output\n\n```\n#{output.uncolorize}\n```"
      github.create_pull_request(
        everypolitician_data_repo,
        'master',
        branch,
        "#{country_slug}: refresh data",
        body
      )
    end
  end

  private

  def branch_exists?(branch_name)
    github.branch(everypolitician_data_repo, branch_name)
    true
  rescue Octokit::NotFound
    false
  end

  # Unset bundler environment variables so it uses the correct Gemfile etc.
  def env
    @env ||= {
      'BUNDLE_GEMFILE' => nil,
      'BUNDLE_BIN_PATH' => nil,
      'RUBYOPT' => nil,
      'RUBYLIB' => nil
    }
  end

  def everypolitician_data_repo
    ENV['EVERYPOLITICIAN_DATA_REPO']
  end

  class SystemCallFail < StandardError; end

  def run(command)
    output = IO.popen(env, command) { |io| io.read }
    return output if $CHILD_STATUS.success?
    fail SystemCallFail, "#{command} #{$CHILD_STATUS}"
  end
end

post '/:country/:legislature' do |country, legislature|
  RebuilderJob.perform_async(country, legislature)
  "Queued rebuild for #{country} #{legislature}\n"
end
