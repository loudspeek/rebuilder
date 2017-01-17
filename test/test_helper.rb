# frozen_string_literal: true
ENV['RACK_ENV'] = 'test'
require 'minitest/autorun'
require 'rack/test'

module SidekiqMinitestSupport
  def after_teardown
    Sidekiq::Queue.new.clear
  end
end

class MiniTest::Spec
  include SidekiqMinitestSupport
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end
end

require 'vcr'

VCR.configure do |config|
  config.cassette_library_dir = 'test/fixtures/vcr_cassettes'
  config.hook_into :webmock
end

require 'minitest/around'

require_relative '../app'
