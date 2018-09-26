# frozen_string_literal: true

require 'test_helper'

describe Build do
  describe '#skip_reason' do
    before do
      stub_pattern(/instructions.json/, 'instructions-tunisia.json')
      stub_pattern(/countries.json/, 'countries.json')
      stub_request(:get, /official.csv/).to_return(body: "id\n1")
    end

    let(:legislature) { EveryPolitician.country('Tunisia').legislature('Majlis') }

    it 'has no reason to skip changed data' do
      stub_request(:get, /api.morph.io/).to_return(body: "id\n2")
      Build.new(legislature, 'official').skip_reason.must_be_nil
    end

    it 'knows to skip unchanged data' do
      stub_request(:get, /api.morph.io/).to_return(body: "id\n1")
      Build.new(legislature, 'official').skip_reason.must_equal 'No morph changes'
    end

    it 'handles a 400 result from morph' do
      stub_request(:get, /api.morph.io/).to_return(status: 400)
      Build.new(legislature, 'official').skip_reason.must_equal 'No morph data'
    end
  end
end
