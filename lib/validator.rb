# frozen_string_literal: true

require_relative 'constants'

module Validator

  def url_valid?(value)
    string_valid?(value, Constants::Regex::URL)
  end

  def path_valid?(value)
    return false unless string_valid?(value, Constants::Regex::PATH)

    File.exist? Bundler.root.to_s + value
  end

  private

  def string_valid?(value, regexp)
    return false unless value.is_a? String

    !value.match(regexp).nil?
  end
end
