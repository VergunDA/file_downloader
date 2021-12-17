# frozen_string_literal: true

require_relative 'initializer'
require_relative 'constants'
require_relative 'logger'
require_relative 'validator'

module FileDownloader

  extend Constants::Defaults
  extend Initializer
  extend Validator

  class << self

    attr_reader :downloads_path
    attr_reader :file_path; private :file_path

    def download_from_file(path = nil, downloads_path = nil)
      puts I18n.t(:start)
      init_paths(path, downloads_path)
      return unless paths_valid?(file_path, @downloads_path)

      valid_urls = read_file
      process_valid_urls(valid_urls)
      puts I18n.t(:log_errors, value: logger.errors) if logger.errors.size > 1
      puts I18n.t(:completed, value: FileDownloader.downloads_path)
    end

    private

    def read_file
      urls = []
      File.foreach(file_path, sep = ' ') do |url|
        url.strip!
        unless url_valid?(url)
          logger.errors << I18n.t(:invalid_url, url: url)
          next
        end

        urls << url
      end
      urls.uniq
    end

    def process_valid_urls(urls)
      threads = []
      urls.each do |url|
        threads << Thread.new { process_valid_url(url) }
      end
      threads.each(&:join)
    end

    def process_valid_url(url)
      puts I18n.t(:download_started, url: url)
      unless can_download?(url)
        puts I18n.t(:download_failed, url: url)
        return
      end

      download_file(url)
      puts I18n.t(:download_completed, url: url)
    end

    def can_download?(url)
      meta_data = fetch_file_metadata(url)
      return false unless meta_data

      meta_data_valid?(meta_data, url)
    end

    def fetch_file_metadata(url)
      response = Faraday.head(url)
      return response.headers if response.status == 200

      logger.errors << I18n.t(:file_is_unavailable, url: url)
      nil
    rescue Faraday::TimeoutError
      logger.errors << I18n.t(:timeout_error, url: url)
    rescue => e
      logger.errors << I18n.t(:response_error, url: url, error: e.message)
    end

    def download_file(url)
      response = Faraday.get(url)
      unless response.status == 200
        logger.errors << I18n.t(:file_is_unavailable, url: url)
        puts I18n.t(:download_failed, url: url)
        return
      end

      save_file(response)
    rescue Faraday::TimeoutError
      logger.errors << I18n.t(:timeout_error, url: url)
    rescue => e
      logger.errors << I18n.t(:response_error, url: url, error: e.message)
    end

    def save_file(response)
      file_name = file_name(response.headers['Etag'], response.headers['content-type'])
      path = downloads_path + "/#{file_name}"
      File.open(path, 'w') { |file| file.write response.body }
    end

    def file_name(etag, content_type)
      type = content_type.scan(Constants::Defaults::FILE_TYPES).first
      name = JSON.parse(etag)
    rescue JSON::ParserError
      name = etag
    ensure
      return "#{name}.#{type}"
    end

    def logger
      @logger ||= Logger.new
    end

    def meta_data_valid?(meta_data, url)
      meta_data_conditions(meta_data).each do |condition|
        next if condition[:block].call

        logger.errors << I18n.t(condition[:message], url: url)
        puts I18n.t(:failed)
        return false
      end
      true
    end
  end
end
