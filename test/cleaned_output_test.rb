# frozen_string_literal: true
require 'test_helper'

describe 'CleanedOutput' do
  describe 'basic output' do
    subject { CleanedOutput.new(output: 'Hello, world') }

    it 'returns it untouched' do
      subject.to_s.must_equal 'Hello, world'
    end
  end

  describe 'output containing Morph API key' do
    subject do
      CleanedOutput.new(
        output:        'Key: test-morph-api-key',
        morph_api_key: 'test-morph-api-key'
      )
    end

    it 'removes the key from the output' do
      subject.to_s.must_equal 'Key: REDACTED'
    end
  end

  describe 'with color escape codes in output' do
    let(:output) { '[0;31;49mTest[0m' }
    subject { CleanedOutput.new(output: output) }

    it 'strips escape codes' do
      subject.to_s.must_equal 'Test'
    end
  end

  describe 'large output' do
    let(:output) { 'x' * 100_000 }
    subject { CleanedOutput.new(output: output) }

    it 'only returns that last 64k' do
      subject.to_s.size.must_equal 64_000
    end
  end
end
