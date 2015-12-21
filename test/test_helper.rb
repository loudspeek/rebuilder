ENV['RACK_ENV'] = 'test'
require 'minitest/autorun'
require 'sidekiq/testing'
require 'rack/test'

Sidekiq::Testing.fake!

module SidekiqMinitestSupport
  def after_teardown
    Sidekiq::Worker.clear_all
  end
end

class MiniTest::Spec
  include SidekiqMinitestSupport
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end
end

require_relative '../app'
