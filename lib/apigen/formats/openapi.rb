# frozen_string_literal: true

require 'yaml'

module Apigen
  module Formats
    module OpenAPI
      ##
      # OpenAPI 3 generator.
      module V3
        class << self
          def generate(api)
            # TODO: Allow overriding any of the hardcoded elements.
            {
              'openapi' => '3.0.0',
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
              'servers' => [
                {
                  'url' => 'http://localhost'
                }
              ],
              'paths' => paths(api),
              'components' => {
                'schemas' => definitions(api)
              }
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
                  'required' => true,
                  'schema' => type(api, v)
                }
              end
              responses = {}
              endpoint.outputs.each do |output|
                response = {
                  'description' => ''
                }
                if output.type != :void
                  response['content'] = {
                    'application/json' => {
                      'schema' => type(api, output.type)
                    }
                  }
                end
                responses[output.status.to_s] = response
              end
              operation = {
                'operationId' => endpoint.name.to_s,
                'description' => '',
                'parameters' => parameters,
                'responses' => responses
              }
              if endpoint.input
                operation['requestBody'] = {
                  'required' => true,
                  'content' => {
                    'application/json' => {
                      'schema' => type(api, endpoint.input)
                    }
                  }
                }
              end
              hash[endpoint.path] = (hash.key?(endpoint.path) ? hash[endpoint.path] : {}).merge(
                endpoint.method.to_s => operation
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
              return { '$ref' => "#/components/schemas/#{type}" } if api.models.key? type
              raise "Unsupported type: #{type}."
            end
          end
        end
      end
    end
  end
end
