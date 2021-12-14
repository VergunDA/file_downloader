# frozen_string_literal: true

require_relative 'lib/constants'

Gem::Specification.new do |s|
  s.name        = 'file_downloader'
  s.version     = Constants::GEM_VERSION
  s.summary     = 'The Big Picture Corp'
  s.description = 'The Big Picture Corp file downlorvm lisader'
  s.authors     = ["Dmytro Verhun"]
  s.email       = 'd.verhun.andersen@gmail.com'
  s.files       = Constants::FILES
  s.homepage    = 'https://rubygems.org/gems/file_downloader'
  s.license       = 'MIT'
  s.add_dependency 'faraday', '~> 1.8'
  s.add_dependency  'rake', '~> 13.0', '>= 13.0.6'
  s.add_development_dependency 'rubocop', '~> 1.23'
  s.add_development_dependency 'rspec', '~> 3.10'
  s.add_development_dependency 'rspec-core', '~> 3.10', '>= 3.10.1'
  s.add_development_dependency 'rspec-expectations', '~> 3.10', '>= 3.10.1'
end