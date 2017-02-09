# frozen_string_literal: true
require 'English'
require_relative 'external_command/result'

class ExternalCommand
  def initialize(command:, env: {})
    @command = command
    @env = env
  end

  def run
    with_tmp_dir do
      Result.new(
        output:       IO.popen(env, command, &:read),
        child_status: $CHILD_STATUS
      )
    end
  end

  private

  attr_reader :env, :command

  def with_tmp_dir(&block)
    Dir.mktmpdir do |tmp_dir|
      Dir.chdir(tmp_dir, &block)
    end
  end
end
