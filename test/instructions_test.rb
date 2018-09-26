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

    it 'knows there is no gender source' do
      subject.source('gender').must_be_nil
    end
  end
end
