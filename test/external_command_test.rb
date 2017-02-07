# frozen_string_literal: true
require 'test_helper'
require_relative '../lib/external_command'

describe 'ExternalCommand' do
  describe 'running a simple command' do
    subject { ExternalCommand.new(command: 'echo Hello, world.').run }

    it 'returns the expected output' do
      subject.output.must_equal "Hello, world.\n"
    end

    it 'is considered to be successful' do
      subject.success?.must_equal true
    end
  end

  describe 'running a command with environment variables set' do
    subject { ExternalCommand.new(command: 'echo Hello, $name.', env: { 'name' => 'Bob' }).run }

    it 'returns the expected output' do
      subject.output.must_equal "Hello, Bob.\n"
    end

    it 'is considered to be successful' do
      subject.success?.must_equal true
    end
  end

  describe 'running an external command that fails' do
    subject { ExternalCommand.new(command: 'echo fail; exit 1').run }

    it 'returns the expected output' do
      subject.output.must_equal "fail\n"
    end

    it 'is considered to be a failure' do
      subject.success?.must_equal false
    end
  end

  describe 'running commands in a tmpdir' do
    let(:other_command) { ExternalCommand.new(command: 'pwd').run }
    subject { ExternalCommand.new(command: 'pwd').run }

    it 'runs in a different directory each time' do
      subject.output.wont_equal other_command.output
    end
  end
end
