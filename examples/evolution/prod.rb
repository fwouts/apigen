# frozen_string_literal: true

require 'apigen/migration'
require 'apigen/rest'

Dir[File.join(__dir__, 'migrations', '*.rb')].each { |file| require file }

api = Apigen::Rest::Api.new
api.migrate(
  AddListUsers,
  AddUserToListUsers
)
api.validate

require 'apigen/formats/openapi'
puts Apigen::Formats::OpenAPI::V3.generate(api)
