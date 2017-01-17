# frozen_string_literal: true
require 'test_helper'

describe 'Rebuilder' do
  describe 'path based rebuild' do
    around { |test| VCR.use_cassette('countries_json', &test) }

    before { post '/Thailand/National_Legislative_Assembly' }

    it 'is successful' do
      assert_equal 200, last_response.status
    end

    it 'queues one job' do
      assert_equal 1, Sidekiq::Queue.new.size
    end

    it 'has the correct arguments' do
      assert_equal ['Thailand', 'National-Legislative-Assembly', nil], Sidekiq::Queue.new.first['args']
    end

    it 'confirms rebuild in response body' do
      assert_equal "Queued rebuild for country=Thailand legislature=National-Legislative-Assembly source=\n", last_response.body
    end
  end

  describe 'parameter based rebuild' do
    before { post '/', country: 'Thailand', legislature: 'National-Legislative-Assembly' }

    it 'is successful' do
      assert_equal 200, last_response.status
    end

    it 'queues one job' do
      assert_equal 1, Sidekiq::Queue.new.size
    end

    it 'has the correct arguments' do
      assert_equal ['Thailand', 'National-Legislative-Assembly', nil], Sidekiq::Queue.new.first['args']
    end

    it 'confirms rebuild in response body' do
      assert_equal "Queued rebuild for country=Thailand legislature=National-Legislative-Assembly source=\n", last_response.body
    end
  end

  describe 'rebuilding a specific source' do
    before { post '/', country: 'Thailand', legislature: 'National-Legislative-Assembly', source: 'gender-balance' }

    it 'is successful' do
      assert_equal 200, last_response.status
    end

    it 'queues one job' do
      assert_equal 1, Sidekiq::Queue.new.size
    end

    it 'has the correct arguments' do
      assert_equal %w(Thailand National-Legislative-Assembly gender-balance), Sidekiq::Queue.new.first['args']
    end

    it 'confirms rebuild in response body' do
      assert_equal "Queued rebuild for country=Thailand legislature=National-Legislative-Assembly source=gender-balance\n", last_response.body
    end
  end
end
