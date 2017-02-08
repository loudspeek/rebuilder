# frozen_string_literal: true
require 'test_helper'
require_relative '../lib/cleaned_output'

describe 'CleanedOutput' do
  describe 'basic output' do
    subject { CleanedOutput.new(output: 'Hello, world') }

    it 'returns it untouched' do
      subject.to_s.must_equal 'Hello, world'
    end
  end

  describe 'redacting strings from output' do
    subject do
      CleanedOutput.new(
        output:     'key=secret pw=opensesame',
        redactions: %w(secret opensesame)
      )
    end

    it 'removes the key from the output' do
      subject.to_s.must_equal 'key=REDACTED pw=REDACTED'
    end
  end

  describe 'redacting single string from output' do
    subject do
      CleanedOutput.new(
        output:     'My password is secret',
        redactions: 'secret'
      )
    end

    it 'removes the key from the output' do
      subject.to_s.must_equal 'My password is REDACTED'
    end
  end

  describe 'passing nil as a redaction' do
    subject { CleanedOutput.new(output: 'Hello, world', redactions: [nil]) }

    it 'returns the expected output' do
      subject.to_s.must_equal 'Hello, world'
    end
  end

  describe 'passing an empty string as a redaction' do
    subject { CleanedOutput.new(output: 'Hello, world', redactions: ['']) }

    it 'returns the expected output' do
      subject.to_s.must_equal 'Hello, world'
    end
  end

  describe 'passed nil instead of redactions array' do
    subject { CleanedOutput.new(output: 'Hello, world', redactions: nil) }

    it 'returns the expected output' do
      subject.to_s.must_equal 'Hello, world'
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

    describe 'configured to a lower max size' do
      subject { CleanedOutput.new(output: 'Hello, world', max_body_size: 5) }

      it 'only returns the last n characters of the body' do
        subject.to_s.must_equal 'world'
      end
    end
  end
end
