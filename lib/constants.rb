# frozen_string_literal: true

module Constants
  GEM_VERSION = '0.1.1'
  FILES = %w[README.md lib/*.rb lib/*.rake]

  module Defaults
    ROOT = Bundler.root.to_s
    DEFAULT_PATH = '/spec/fixtures/valid_file.txt'
    DOWNLOADS_PATH = "#{ROOT}/downloads"
    LOG_PATH = "#{ROOT}/process.log"
    FILE_TYPES = /jpeg|apng|gif|png|svg+xml|webp|bmp|x-icon|tiff/
  end

  module Regex
    URL = %r{\A((http|https):\/\/)[\w]+([\-\.]{1}[\w]+)*\.[\w]{2,25}(:[0-9]{1,5})?(\/.*)?\z}
    PATH = %r{([a-zA-Z0-9\s_\\.\-\(\):])+(.txt|.csv)$}
  end

  module Restrictions
    BATCH_SIZE = 5
    MAX_SIZE = 20_000_000
    MIN_SIZE = 10
    SPACE_LIMIT = 1000_000
    AVAILABLE_TYPES = %w[image/jpeg image/tiff image/x-icon image/bmp image/webp
                         image/svg+xml image/png image/gif image/avif image/apng]
  end
end
