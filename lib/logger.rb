# frozen_string_literal: true
require_relative 'constants'

class Logger

  include Constants::Defaults

  attr_reader :path
  attr_reader :errors

  def initialize
    @path = Constants::Defaults::LOG_PATH
    @errors = []
  end

  def add_to_log(row)
    File.open(path, 'w') do |f|
      f.write "#{row}\n"
    end
  end
end
