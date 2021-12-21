require 'faraday'
require 'json'
require 'i18n'

I18n.load_path << Dir[File.expand_path("config/locales") + "/*.yml"]

module Initializer

  attr_reader :downloads_path
  attr_reader :file_path; private :file_path
  attr_reader :separator; private :separator

  def init_instance_variables(path, downloads_path, separator)
    init_file_path(path)
    init_download_path(downloads_path)
    @separator = separator
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
                        path = Constants::Defaults::DOWNLOADS_PATH
                        Dir.mkdir path unless File.directory?(path)
                        path
                      end
  end
end