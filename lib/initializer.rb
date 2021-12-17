require 'faraday'
require 'json'
require 'i18n'

I18n.load_path << Dir[File.expand_path("config/locales") + "/*.yml"]

module Initializer

  def init_paths(path, downloads_path)
    init_file_path(path)
    init_download_path(downloads_path)
  end

  def init_file_path(path)
    return unless path

    @file_path = if File.exist? Constants::Defaults::ROOT + path
                   Constants::Defaults::ROOT + path
                 elsif File.exist? path
                   path
                 end
  end

  def init_download_path(path)
    @downloads_path = if path && File.directory?("#{Constants::Defaults::ROOT}/#{path}")
                        Constants::Defaults::ROOT + path
                      elsif path && File.directory?(path)
                        path
                      elsif path.nil?
                        Constants::Defaults::DOWNLOADS_PATH
                      end
  end
end