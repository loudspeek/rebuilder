# frozen_string_literal: true
require 'English'
require_relative 'external_command/result'

class ExternalCommand
  def initialize(command:, env: {})
    @command = command
    @env = env
  end

  def run
    Dir.mktmpdir do
      Result.new(
        output:       IO.popen(default_env.merge(env), command, &:read),
        child_status: $CHILD_STATUS
      )
    end
  end

  private

  attr_reader :env, :command

  # Unset bundler environment variables so it uses the correct Gemfile etc.
  def default_env
    @default_env ||= {
      'BUNDLE_GEMFILE'                => nil,
      'BUNDLE_BIN_PATH'               => nil,
      'RUBYOPT'                       => nil,
      'RUBYLIB'                       => nil,
      'NOKOGIRI_USE_SYSTEM_LIBRARIES' => '1',
    }
  end
end
