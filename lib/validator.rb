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

  def paths_valid?(file_path, downloads_path)
    message, path = if file_path.nil?
                      [:invalid_path, file_path]
                    elsif downloads_path.nil?
                      [:invalid_download_path, downloads_path]
                    end
    return true unless message

    puts I18n.t(message, value: path)
    false
  end

  def meta_data_conditions(meta_data)
    [
      {
        message: :headers_invalid,
        block: -> { response_headers_valid?(meta_data) }
      },
      {
        message: :invalid_content_type,
        block: -> { content_type_valid?(meta_data['content-type']) }
      },
      {
        message: :file_too_large,
        block: -> { max_size_valid?(meta_data['content-length'].to_i) }
      },
      {
        message: :file_too_small,
        block: -> { min_size_valid?(meta_data['content-length'].to_i) }
      },
      {
        message: :out_of_space,
        block: -> { space_available?(meta_data['content-length'].to_i) }
      }
    ]
  end
end
