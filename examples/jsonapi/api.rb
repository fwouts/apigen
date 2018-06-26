# frozen_string_literal: true

require 'apigen/rest'

##
# An example of a JSON:API-compliant API defined with Apigen.
module JsonApiExample
  API = Apigen::Rest::Api.new

  require_relative 'endpoints/list-articles'
  require_relative 'models/article'
  require_relative 'models/comment'
  require_relative 'models/entity_reference'
  require_relative 'models/link'
  require_relative 'models/person'

  API.validate

  require 'apigen/formats/openapi'
  puts Apigen::Formats::OpenAPI::V3.generate(API)
end
