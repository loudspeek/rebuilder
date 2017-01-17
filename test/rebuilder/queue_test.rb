# frozen_string_literal: true
require 'test_helper'

describe Rebuilder::Queue do
  describe 'rebuilding the same legislature multiple times' do
    before do
      2.times do
        Rebuilder::Queue.new.add('Thailand', 'National-Legislative-Assembly', 'gender-balance')
      end
    end

    it 'only queues one job up' do
      assert_equal 1, Sidekiq::Queue.new.size
    end
  end
end
