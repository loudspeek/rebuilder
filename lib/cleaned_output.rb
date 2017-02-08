# frozen_string_literal: true
require 'colorize'
require 'erb'

class CleanedOutput
  def initialize(output:, redactions: [], max_body_size: 64_000)
    @output = output
    @redactions = redactions
    @max_body_size = max_body_size
  end

  def to_s
    output_with_transforms_applied
  end

  private

  attr_reader :output, :redactions, :max_body_size

  def output_with_transforms_applied
    truncate(uncolorize(redact(output)))
  end

  def truncate(out)
    out[-max_body_size..-1] || out
  end

  def uncolorize(out)
    out.uncolorize
  end

  def redact(out)
    redactions.reduce(out) do |s, redaction|
      s.gsub(ERB::Util.url_encode(redaction), 'REDACTED')
    end
  end
end
