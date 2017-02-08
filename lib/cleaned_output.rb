# frozen_string_literal: true
require 'colorize'

class CleanedOutput
  def initialize(output:, morph_api_key: ENV['MORPH_API_KEY'])
    @output = output
    @morph_api_key = morph_api_key
  end

  def to_s
    (cleaned_output[-64_000..-1] || cleaned_output).uncolorize
  end

  private

  attr_reader :output, :morph_api_key

  def cleaned_output
    return output if morph_api_key_encoded.empty?
    output.gsub(morph_api_key_encoded, 'REDACTED')
  end

  def morph_api_key_encoded
    ERB::Util.url_encode(morph_api_key)
  end
end
