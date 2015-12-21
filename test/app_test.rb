require 'test_helper'

describe 'Rebuilder' do
  describe 'path based rebuild' do
    before { post '/Australia/Senate' }

    it 'is successful' do
      assert_equal 200, last_response.status
    end

    it 'queues one job' do
      assert_equal 1, RebuilderJob.jobs.size
    end

    it 'has the correct arguments' do
      assert_equal %w(Australia Senate), RebuilderJob.jobs.first['args']
    end

    it 'confirms rebuild in response body' do
      assert_equal "Queued rebuild for Australia Senate\n", last_response.body
    end
  end
end
