# frozen_string_literal: true

Gem::Specification.new do |s|
  s.name        = 'apigen'
  s.version     = '0.0.6'
  s.date        = '2017-06-18'
  s.summary     = 'OpenAPI spec generator'
  s.description = 'A simple DSL to generate OpenAPI and/or JSON Schema definitions in Ruby.'
  s.authors     = ['Francois Wouts']
  s.email       = 'f@zenc.io'
  s.files       = [
    'lib/apigen/model.rb',
    'lib/apigen/rest.rb',
    'lib/apigen/util.rb',
    'lib/apigen/formats/jsonschema.rb',
    'lib/apigen/formats/openapi.rb',
    'lib/apigen/formats/swagger.rb'
  ]
  s.homepage    = 'https://rubygems.org/gems/apigen'
  s.license     = 'MIT'
end
