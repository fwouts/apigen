# frozen_string_literal: true

require 'apigen/rest'

api = Apigen::Rest::Api.new

api.endpoint :test do
  method :get
  path '/users'
  output :success do
    description 'Success'
    status 200
    type :void
  end
end

api.model :user_profile do
  type :object do
    name :string
    avatar_url :string
  end
end

# Ensure that the API spec is valid.
api.validate

# Output Swagger (OpenAPI 2).
require 'apigen/formats/swagger'
puts Apigen::Formats::Swagger::V2.generate api

# Output OpenAPI 3.
require 'apigen/formats/openapi'
puts Apigen::Formats::OpenAPI::V3.generate api

# Output JSON schema.
require 'apigen/formats/jsonschema'
puts Apigen::Formats::JsonSchema::Draft7.generate api
