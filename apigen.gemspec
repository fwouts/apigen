# frozen_string_literal: true

Gem::Specification.new do |s|
  s.name        = 'apigen'
  s.version     = '0.0.7'
  s.date        = '2017-06-18'
  s.summary     = 'OpenAPI spec generator'
  s.description = 'A simple DSL to generate OpenAPI and/or JSON Schema definitions in Ruby.'
  s.authors     = ['Francois Wouts']
  s.email       = 'f@zenc.io'
  s.files       = Dir.glob('lib/**/*.rb')
  s.homepage    = 'https://rubygems.org/gems/apigen'
  s.license     = 'MIT'
end
