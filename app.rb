require 'bundler'
Bundler.require
Dotenv.load

require 'active_support/core_ext'
require 'English'

# Mixin to provide a GitHub client and helpers.
module Github
  def github
    @github ||= Octokit::Client.new(access_token: ENV['GITHUB_ACCESS_TOKEN'])
  end

  def with_git_repo(repo_name, options)
    repo = github.repository(repo_name)
    branch = options.fetch(:branch, 'master')
    message = options.fetch(:message)
    with_tmp_dir do |dir|
      git = Git.clone(clone_url(repo.clone_url), '.')
      git.config('user.name', github.login)
      git.config('user.email', github.emails.first[:email])
      git.branch(branch).checkout
      yield
      if git.status.changed.any? || git.status.untracked.any?
        git.add
        git.commit(message)
        git.push
      end
    end
  end

  def clone_url(uri)
    repo_clone_url = URI.parse(uri)
    repo_clone_url.user = github.login
    repo_clone_url.password = github.access_token
    repo_clone_url
  end

  def with_tmp_dir(&block)
    Dir.mktmpdir do |tmp_dir|
      Dir.chdir(tmp_dir, &block)
    end
  end
end

# Rebuild a given country's legislature information
class RebuilderJob
  include Sidekiq::Worker
  include Github

  class SystemCallFail < StandardError; end

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

  def system(*args)
    fail SystemCallFail, "#{args} #{$CHILD_STATUS}" unless Kernel.system(*args)
  end
end

post '/:country/:legislature' do |country, legislature|
  RebuilderJob.perform_async(country, legislature)
  "Queued rebuild for #{country} #{legislature}\n"
end
