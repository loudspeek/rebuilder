# frozen_string_literal: true
require 'colorize'

class CleanedOutput
  def initialize(output:)
    @output = output
  end

  def to_s
    cleaned_output[-64_000..-1] || cleaned_output
  end

  private

  def cleaned_output
    output.gsub(morph_api_key, 'REDACTED').uncolorize
  end

  def morph_api_key
    ERB::Util.url_encode(ENV['MORPH_API_KEY'])
  end

  attr_reader :output
end
