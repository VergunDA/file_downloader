# frozen_string_literal: true

require 'rake'
require_relative 'lib/file_downloader'

namespace :file_downloader do

  desc 'Download files'
  task :download_from_file,[:path, :downloads_path] do |*args|
    FileDownloader.download_from_file args[1][:path], args[1][:downloads_path]
  end
end

