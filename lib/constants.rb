# frozen_string_literal: true

module Constants
  GEM_VERSION = '0.1.1'
  FILES = %w[README.md lib/*.rb lib/*.rake]

  module Regex
    URL = %r{\A((http|https):\/\/)?[\w]+([\-\.]{1}[\w]+)*\.[\w]{2,25}(:[0-9]{1,5})?(\/.*)?\z}
    PATH = %r{([a-zA-Z0-9\s_\\.\-\(\):])+(.txt|.csv)$}
  end

end
