# frozen_string_literal: true

require 'test_helper'

describe 'Instructions' do
  describe 'Tunisia' do
    before do
      stub_pattern(/instructions.json/, 'instructions-tunisia.json')
      stub_pattern(/countries.json/, 'countries.json')
    end

    let(:legislature) { EveryPolitician.country('Tunisia').legislature('Majlis') }
    subject { EveryPolitician::Instructions.new(legislature) }

    it 'knows where to get wikidata' do
      src = subject.source('wikidata')
      # TODO: rewrite to not access a private method
      src.send(:github_data_url).must_include 'sources/morph/wikidata.csv'
    end

    it 'knows gender is not a morph-based source' do
      subject.source('gender').morph?.must_equal false
    end

    it 'handles a 400 result from morph' do
      src = subject.source('official')
      stub_request(:get, /api.morph.io/).to_return(status: 400)
      src.fresh_data.must_be_nil
    end
  end
end
