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
gem 'sucker_punch'
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

# The below are gems actually required by representa itself, but in order for them to build correctly on Heroku,
# they have to be declared in the Gemfile here and not in the nested Gemfile of the representa app.
# If they aren't in here, you end up with "can't find stdio.h" errors.
gem 'close_old_pull_requests', github: 'everypolitician/close_old_pull_requests'
gem 'csv_to_popolo', github: 'tmtmtmtm/csv_to_popolo'
gem 'csvlint'
gem 'deep_merge'
gem 'everypolitician-dataview-terms', github: 'everypolitician/everypolitician-dataview-terms'
gem 'everypolitician-pull_request', github: 'everypolitician/everypolitician-pull_request'
gem 'facebook_username_extractor', '~> 0.3.0', github: 'everypolitician/facebook_username_extractor'
gem 'field_serializer', github: 'everypolitician/field_serializer'
gem 'fuzzy_match'
gem 'json'
gem 'rcsv'
gem 'require_all', '~> 1.0'
gem 'sass'
gem 'slop', '~> 3.6.0' # tied to pry version
gem 'twitter_username_extractor', github: 'everypolitician/twitter_username_extractor'
gem 'unicode_utils'
gem 'wikisnakker', github: 'everypolitician/wikisnakker'
gem 'yajl-ruby', require: 'yajl'
