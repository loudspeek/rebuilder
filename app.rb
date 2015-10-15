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
    with_git_repo(everypolitician_data_repo, options) do
      # Unset bundler environment variables so it uses the correct Gemfile etc.
      system(env, 'bundle install')
      Dir.chdir(File.join('data', country_slug, legislature_slug)) do
        system(env, 'bundle exec rake clobber default')
      end
    end
  end

  private

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

  def system(*args)
    fail SystemCallFail, "#{args} #{$CHILD_STATUS}" unless Kernel.system(*args)
  end
end

post '/:country/:legislature' do |country, legislature|
  RebuilderJob.perform_async(country, legislature)
  "Queued rebuild for #{country} #{legislature}\n"
end
