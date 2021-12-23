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

    def download_from_file(path = nil, downloads_path = nil, separator = ' ')
      puts I18n.t(:start)
      init_instance_variables(path, downloads_path, separator)
      return unless paths_valid?(path, downloads_path)

      perform_downloading
      puts I18n.t(:log_errors, value: logger.errors) if logger.errors.size > 1
      puts I18n.t(:completed, value: FileDownloader.downloads_path)
    end

    private

    def perform_downloading
      urls = []
      File.foreach(file_path, sep = separator) do |url|
        url.strip!
        next unless url_to_process?(url)

        urls << url
        urls = check_process_valid_urls(urls)
      end
      process_valid_urls(urls.uniq)
    end

    def check_process_valid_urls(urls)
      return urls unless urls.count == Constants::Restrictions::BATCH_SIZE

      process_valid_urls(urls.uniq)
      []
    end

    def url_to_process?(url)
      return true if url_valid?(url)

      logger.errors << I18n.t(:invalid_url, url: url)
      false
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
      meta_data = fetch_file_metadata(url)
      unless can_download?(url, meta_data)
        puts I18n.t(:download_failed, url: url)
        return
      end

      if url_downloaded?(meta_data["Etag"], meta_data['content-type'])
        puts I18n.t(:download_exists, url: url)
      else
        download_file(url)
      end
    end

    def can_download?(url, meta_data)
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

    def url_downloaded?(etag, content_type)
      return false unless etag

      File.exist? downloads_path + "/#{file_name(etag, content_type)}"
    end

    def download_file(url)
      response = Faraday.get(url)
      unless response.status == 200
        logger.errors << I18n.t(:file_is_unavailable, url: url)
        puts I18n.t(:download_failed, url: url)
        return
      end

      save_file(response)
      puts I18n.t(:download_completed, url: url)
    rescue Faraday::TimeoutError
      logger.errors << I18n.t(:timeout_error, url: url)
    rescue => e
      logger.errors << I18n.t(:response_error, url: url, error: e.message)
    end

    def save_file(response)
      name = file_name(response.headers['Etag'], response.headers['content-type'])
      path = downloads_path + "/#{name}"
      File.open(path, 'w') { |file| file.write response.body }
    end

    def file_name(etag, content_type)
      type = content_type.scan(Constants::Defaults::FILE_TYPES).first
      name = etag ? parse_etag(etag) : "image_#{Time.now.to_i}"
      "#{name}.#{type}"
    end

    def parse_etag(etag)
      JSON.parse(etag)
    rescue JSON::ParserError
      return etag
    end

    def meta_data_valid?(meta_data, url)
      meta_data_conditions(meta_data).each do |condition|
        next if condition[:block].call

        logger.errors << I18n.t(condition[:message], url: url)
        return false
      end
      true
    end

    def paths_valid?(file, downloads)
      message, path = if file_path.nil?
                        [:invalid_path, file]
                      elsif downloads_path.nil?
                        [:invalid_download_path, downloads]
                      end
      return true unless message

      puts I18n.t(message, value: path)
      false
    end

    def logger
      @logger ||= Logger.new
    end
  end
end
