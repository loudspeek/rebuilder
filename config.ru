require_relative './app'
require 'sidekiq'
require 'sidekiq/web'

Sidekiq.configure_client do |config|
  config.redis = { size: 1 }
end

map '/sidekiq' do
  use Rack::Auth::Basic, 'Protected Area' do |username, password|
    username == 'sidekiq' && password == ENV.fetch('SIDEKIQ_PASSWORD')
  end

  run Sidekiq::Web
end

run Sinatra::Application
