# frozen_string_literal: true
require 'colorize'
require 'erb'

class CleanedOutput
  def initialize(output:, redactions: [])
    @output = output
    @redactions = redactions
  end

  def to_s
    output_with_transforms_applied
  end

  private

  attr_reader :output, :redactions

  def output_with_transforms_applied
    truncate(uncolorize(redact(output)))
  end

  def truncate(out)
    out[-64_000..-1] || out
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
