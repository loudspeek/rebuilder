require 'bundler'
Bundler.require
Dotenv.load

require 'active_support/core_ext'
require 'English'

# Mixin to provide a GitHub client and helpers.
module Github
  class SystemCallFail < StandardError; end

  def github
    @github ||= Octokit::Client.new(access_token: ENV['GITHUB_ACCESS_TOKEN'])
  end

  def with_git_repo(repo_name, options)
    repo = github.repository(repo_name)
    branch = options.fetch(:branch, 'master')
    with_tmp_dir do |dir|
      system("git clone --quiet #{clone_url(repo.clone_url)} #{dir}")
      system("git checkout -B #{branch}")
      yield
      git_commit_and_push(options.merge(branch: branch))
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

  def git_config
    @git_config ||= "-c user.name='#{github.login}' " \
      "-c user.email='#{github.emails.first[:email]}'"
  end

  def git_commit_and_push(options)
    branch_name = options.fetch(:branch)
    message = options.fetch(:message)
    system('git add .')
    system(%(git #{git_config} commit --quiet --message="#{message}" || true))
    system("git push --quiet origin #{branch_name}")
  end

  def system(*args)
    fail SystemCallFail, "#{args} #{$CHILD_STATUS}" unless Kernel.system(*args)
  end
end

# Rebuild a given country's legislature information
class RebuilderJob
  include Sidekiq::Worker
  include Github

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
end

post '/:country/:legislature' do |country, legislature|
  RebuilderJob.perform_async(country, legislature)
  "Queued rebuild for #{country} #{legislature}\n"
end
