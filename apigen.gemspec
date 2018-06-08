Gem::Specification.new do |s|
  s.name        = 'apigen'
  s.version     = '0.0.2'
  s.date        = '2017-05-30'
  s.summary     = 'OpenAPI spec generator'
  s.description = 'A simple DSL to describe your OpenAPI spec in Ruby.'
  s.authors     = ['Francois Wouts']
  s.email       = 'f@zenc.io'
  s.files       = [
    'lib/apigen/model.rb',
    'lib/apigen/rest.rb',
    'lib/apigen/formats/swagger.rb',
  ]
  s.homepage    = 'https://rubygems.org/gems/apigen'
  s.license     = 'MIT'
end
