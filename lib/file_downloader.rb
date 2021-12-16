# frozen_string_literal: true
require_relative 'validator'
require_relative 'constants'
require_relative 'messages'
require 'json'
require_relative 'logger'
require 'faraday'

module FileDownloader

  extend Validator
  extend Messages
  extend Constants::Defaults

  class << self

    attr_reader :logger
    attr_reader :downloads_path

    def download_from_file(path = Constants::Defaults::DEFAULT_PATH, downloads_path = Constants::Defaults::DOWNLOADS_PATH)
      @downloads_path = downloads_path
      @logger = Logger.new
      return unless path_valid? path

      valid_urls = read_file(path)
      process_valid_urls(valid_urls)
      puts "ERRORS: #{logger.errors}" if logger.errors.size > 1
    end

    def read_file(path)
      urls = []
      data = File.read(Constants::Defaults::ROOT + path)
      data.split(' ').each do |url|
        url.strip!
        unless url_valid?(url)
          logger.errors << invalid_url_message(url)
          next
        end

        urls << url
      end
      urls
    end

    def process_valid_urls(urls)
      urls.each do |url|
        puts "Process: #{url}"
        download_file(url)
      end
    end

    def download_file(url)
      unless can_download?(url)
        puts "FAILED"
        return
      end

      response = Faraday.get(url)
      unless response.status == 200
        logger.errors << file_is_unavailable_message(url)
        puts "FAILED"
        return
      end

      save_file(response)
    rescue Faraday::TimeoutError
      logger.errors << timeout_error_message(url)
    rescue => e
      logger.errors << error_message(url, e.message)
    end

    def can_download?(url)
      response = Faraday.head(url)
      unless response.status == 200
        logger.errors << file_is_unavailable_message(url)
        return false
      end

      unless response_headers_valid?(response.headers)
        logger.errors << headers_invalid_message(url)
        return false
      end

      unless content_type_valid?(response.headers['content-type'])
        logger.errors << invalid_content_type_message(url)
        return false
      end

      unless max_size_valid?(response.headers['content-length'].to_i)
        logger.errors << file_too_large_message(url)
        return false
      end

      unless min_size_valid?(response.headers['content-length'].to_i)
        logger.errors << file_too_small_message(url)
        return false
      end

      unless space_available?(response.headers['content-length'].to_i)
        logger.errors << out_of_space_message(url)
        return false
      end

      true
    end

    def save_file(response)
      file_name = file_name(response.headers['Etag'], response.headers['content-type'])
      path = downloads_path + "/#{file_name}"
      File.open(path, 'w') do |file|
        file.write response.body
      end
      puts "OK"
    end

    def file_name(etag, content_type)
      type = content_type.scan(Constants::Defaults::FILE_TYPES).first
      name = JSON.parse(etag)
      "#{name}.#{type}"
    rescue JSON::ParseError
      name = etag
    ensure
      "#{name}.#{type}"
    end
  end
end
