# frozen_string_literal: true

require 'sys/filesystem'

module Validator

  extend Sys

  def url_valid?(value)
    string_valid?(value, Constants::Regex::URL)
  end

  def path_valid?(path)
    return false unless string_valid?(path, Constants::Regex::PATH)

    File.exist? Bundler.root.to_s + path
  end

  def response_headers_valid?(headers)
    headers['content-type'].is_a?(String) &&
      headers['content-length'].is_a?(String) &&
      headers['Etag'].is_a?(String)
  end

  def space_available?(size)
    (current_free_space - size) > Constants::Restrictions::SPACE_LIMIT
  end

  def content_type_valid?(type)
    Constants::Restrictions::AVAILABLE_TYPES.include? type
  end

  def max_size_valid?(size)
    Constants::Restrictions::MAX_SIZE > size
  end

  def min_size_valid?(size)
    Constants::Restrictions::MIN_SIZE < size
  end

  def string_valid?(value, regexp)
    return false unless value.is_a? String

    !value.match(regexp).nil?
  end

  def current_free_space
    stat = Sys::Filesystem.stat('/')
    stat.blocks_free * stat.block_size
  end
end
