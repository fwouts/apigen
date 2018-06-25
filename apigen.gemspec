# frozen_string_literal: true

Gem::Specification.new do |s|
  s.name        = 'apigen'
  s.version     = '0.0.10'
  s.date        = Time.now.strftime('%Y-%m-%d')
  s.summary     = 'OpenAPI spec generator'
  s.description = 'A simple DSL to generate OpenAPI and/or JSON Schema definitions in Ruby.'
  s.authors     = ['Francois Wouts']
  s.email       = 'f@zenc.io'
  s.files       = Dir.glob('lib/**/*.rb')
  s.homepage    = 'https://rubygems.org/gems/apigen'
  s.license     = 'MIT'
end
