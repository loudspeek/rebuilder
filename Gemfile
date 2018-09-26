# frozen_string_literal: true
source 'https://rubygems.org'
git_source(:github) { |repo_name| "https://github.com/#{repo_name}.git" }

ruby '2.3.3'

gem 'activesupport', require: 'active_support'
gem 'colorize'
gem 'dotenv'
gem 'everypolitician'
gem 'everypolitician-popolo', github: 'everypolitician/everypolitician-popolo'
gem 'json5'
gem 'octokit'
gem 'puma'
gem 'rake'
gem 'rest-client'
gem 'rubocop'
gem 'sidekiq'
gem 'sinatra'

group :test do
  gem 'minitest'
  gem 'minitest-around'
  gem 'pry'
  gem 'rack-test'
  gem 'vcr'
  gem 'webmock'
end

# Report exceptions to rollbar.com
gem 'oj', '~> 2.12.14'
gem 'rollbar', '~> 2.13'
