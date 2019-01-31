# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |repo_name| "https://github.com/#{repo_name}.git" }

ruby '2.4.4'

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
gem 'sidekiq'
gem 'sinatra'

group :test do
  gem 'minitest'
  gem 'minitest-around'
  gem 'pry'
  gem 'rack-test'
  gem 'rubocop'
  gem 'vcr'
  gem 'webmock'
end

group :development do
  gem 'derailed'
end

# Report exceptions to rollbar.com
gem 'oj'
gem 'rollbar'
