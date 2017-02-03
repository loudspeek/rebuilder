# frozen_string_literal: true
require 'test_helper'

describe 'Rebuilder' do
  describe 'path based rebuild' do
    around { |test| VCR.use_cassette('countries_json', &test) }

    before { post '/Thailand/National_Legislative_Assembly' }

    it 'is successful' do
      last_response.status.must_equal 200
    end

    it 'queues one job' do
      RebuilderJob.jobs.size.must_equal 1
    end

    it 'has the correct arguments' do
      RebuilderJob.jobs.first['args'].must_equal ['Thailand', 'National-Legislative-Assembly', nil]
    end

    it 'confirms rebuild in response body' do
      last_response.body.must_equal "Queued rebuild for country=Thailand legislature=National-Legislative-Assembly source=\n"
    end
  end

  describe 'parameter based rebuild' do
    before { post '/', country: 'Thailand', legislature: 'National-Legislative-Assembly' }

    it 'is successful' do
      last_response.status.must_equal 200
    end

    it 'queues one job' do
      RebuilderJob.jobs.size.must_equal 1
    end

    it 'has the correct arguments' do
      RebuilderJob.jobs.first['args'].must_equal ['Thailand', 'National-Legislative-Assembly', nil]
    end

    it 'confirms rebuild in response body' do
      last_response.body.must_equal "Queued rebuild for country=Thailand legislature=National-Legislative-Assembly source=\n"
    end
  end

  describe 'rebuilding a specific source' do
    before { post '/', country: 'Thailand', legislature: 'National-Legislative-Assembly', source: 'gender-balance' }

    it 'is successful' do
      last_response.status.must_equal 200
    end

    it 'queues one job' do
      RebuilderJob.jobs.size.must_equal 1
    end

    it 'has the correct arguments' do
      RebuilderJob.jobs.first['args'].must_equal %w(Thailand National-Legislative-Assembly gender-balance)
    end

    it 'confirms rebuild in response body' do
      last_response.body.must_equal "Queued rebuild for country=Thailand legislature=National-Legislative-Assembly source=gender-balance\n"
    end
  end

  describe 'url-based rebuilds using country and legislature slugs' do
    describe 'without a source' do
      before { post '/rebuild/Thailand/National-Legislative-Assembly' }

      it 'is successful' do
        last_response.status.must_equal 200
      end

      it 'queues one job' do
        RebuilderJob.jobs.size.must_equal 1
      end

      it 'has the correct arguments' do
        RebuilderJob.jobs.first['args'].must_equal ['Thailand', 'National-Legislative-Assembly', nil]
      end

      it 'confirms rebuild in response body' do
        last_response.body.must_equal "Queued rebuild for country=Thailand legislature=National-Legislative-Assembly source=\n"
      end
    end

    describe 'with a source' do
      before { post '/rebuild/Thailand/National-Legislative-Assembly/gender-balance' }

      it 'is successful' do
        last_response.status.must_equal 200
      end

      it 'queues one job' do
        RebuilderJob.jobs.size.must_equal 1
      end

      it 'has the correct arguments' do
        RebuilderJob.jobs.first['args'].must_equal %w(Thailand National-Legislative-Assembly gender-balance)
      end

      it 'confirms rebuild in response body' do
        last_response.body.must_equal "Queued rebuild for country=Thailand legislature=National-Legislative-Assembly source=gender-balance\n"
      end
    end
  end
end
