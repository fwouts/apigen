# frozen_string_literal: true

require 'yaml'

module Apigen
  module Formats
    module Swagger
      ##
      # Swagger 2 (aka OpenAPI 2) generator.
      module V2
        class << self
          def generate(api)
            # TODO: Allow overriding any of the hardcoded elements.
            {
              'swagger' => '2.0',
              'info' => {
                'version' => '1.0.0',
                'title' => 'API',
                'description' => '',
                'termsOfService' => '',
                'contact' => {
                  'name' => ''
                },
                'license' => {
                  'name' => ''
                }
              },
              'host' => 'localhost',
              'basePath' => '/',
              'schemes' => %w[
                http
                https
              ],
              'consumes' => [
                'application/json'
              ],
              'produces' => [
                'application/json'
              ],
              'paths' => paths(api),
              'definitions' => definitions(api)
            }.to_yaml
          end

          private

          def paths(api)
            hash = {}
            api.endpoints.each do |endpoint|
              parameters = []
              endpoint.path_parameters.properties.each do |k, v|
                parameters << {
                  'in' => 'path',
                  'name' => k.to_s,
                  'required' => true
                }.merge(type(api, v))
              end
              endpoint.query_parameters.properties.each do |k, v|
                optional = v.is_a?(Apigen::OptionalType)
                parameter_type = optional ? v.type : v
                parameters << {
                  'in' => 'query',
                  'name' => k.to_s,
                  'required' => !optional
                }.merge(type(api, parameter_type))
              end
              if endpoint.input
                parameters << {
                  'name' => 'input',
                  'in' => 'body',
                  'required' => true,
                  'schema' => type(api, endpoint.input)
                }
              end
              responses = {}
              endpoint.outputs.each do |output|
                response = {
                  'description' => ''
                }
                if output.type != :void
                  response['schema'] = type(api, output.type)
                end
                responses[output.status.to_s] = response
              end
              hash[endpoint.path] = (hash.key?(endpoint.path) ? hash[endpoint.path] : {}).merge(
                endpoint.method.to_s => {
                  'description' => '',
                  'parameters' => parameters,
                  'responses' => responses
                }
              )
            end
            hash
          end

          def definitions(api)
            hash = {}
            api.models.each do |key, model|
              hash[key.to_s] = type api, model.type
            end
            hash
          end

          def type(api, type)
            case type
            when Apigen::ObjectType
              required_fields = []
              type.properties.each do |k, v|
                required_fields << k.to_s unless v.is_a? Apigen::OptionalType
              end
              {
                'type' => 'object',
                'properties' => type.properties.map do |k, v|
                  # We're already reflecting the fact that fields are optional with required fields.
                  property_type = v.is_a?(Apigen::OptionalType) ? v.type : v
                  [k.to_s, type(api, property_type)]
                end.to_h,
                'required' => required_fields
              }
            when Apigen::ArrayType
              {
                'type' => 'array',
                'items' => type(api, type.type)
              }
            when Apigen::OptionalType
              raise 'OptionalType fields are only supported within object types.'
            when :string
              {
                'type' => 'string'
              }
            when :int32
              {
                'type' => 'integer',
                'format' => 'int32'
              }
            when :bool
              {
                'type' => 'boolean'
              }
            else
              return { '$ref' => "#/definitions/#{type}" } if api.models.key? type
              raise "Unsupported type: #{type}."
            end
          end
        end
      end
    end
  end
end
