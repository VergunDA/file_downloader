require_relative 'contexts/web_stubs'

RSpec.configure do |config|
  config.include_context 'web stubs', include_shared: true
end
