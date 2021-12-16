# frozen_string_literal: true

require 'faraday'
require 'json'
require_relative 'constants'
require_relative 'logger'
require_relative 'messages'
require_relative 'validator'

module FileDownloader

  extend Validator
  extend Messages
  extend Constants::Defaults

  class << self

    attr_reader :downloads_path
    attr_reader :logger; private :logger
    attr_reader :file_path; private :logger

    def download_from_file(path = nil, downloads_path = nil)
      @downloads_path = downloads_path || Constants::Defaults::DOWNLOADS_PATH
      @file_path = path || Constants::Defaults::DEFAULT_PATH
      @logger = Logger.new
      return unless path_valid?(file_path)

      valid_urls = read_file
      process_valid_urls(valid_urls)
      puts "ERRORS: #{logger.errors}" if logger.errors.size > 1
    end

    private

    def read_file
      urls = []
      File.foreach(Constants::Defaults::ROOT + file_path, sep = ' ') do |url|
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
      threads = []
      urls.each do |url|
        threads << Thread.new { process_valid_url(url) }
      end
      threads.each(&:join)
    end

    def process_valid_url(url)
      puts "Download from #{url} is started"
      unless can_download?(url)
        puts "FAILED"
        return
      end

      download_file(url)
      puts "Download from #{url} is completed successfully"
    end

    def download_file(url)
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
      meta_data = fetch_file_metadata(url)
      return false unless meta_data

      meta_data_valid?(meta_data, url)
    end

    def fetch_file_metadata(url)
      response = Faraday.head(url)
      return response.headers if response.status == 200

      logger.errors << file_is_unavailable_message(url)
      nil
    end

    def save_file(response)
      file_name = file_name(response.headers['Etag'], response.headers['content-type'])
      path = downloads_path + "/#{file_name}"
      File.open(path, 'w') { |file| file.write response.body }
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
