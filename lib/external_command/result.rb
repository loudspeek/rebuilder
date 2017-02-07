# frozen_string_literal: true

class ExternalCommand
  class Result
    attr_reader :output

    def initialize(output:, child_status:)
      @output = output
      @child_status = child_status
    end

    def success?
      child_status.success?
    end

    private

    attr_reader :child_status
  end
end
