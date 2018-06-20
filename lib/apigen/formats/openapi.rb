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
              parameters.concat(endpoint.path_parameters.properties.map { |name, type| path_parameter(api, name, type) })
              parameters.concat(endpoint.query_parameters.properties.map { |name, type| query_parameter(api, name, type) })
              responses = endpoint.outputs.map { |output| response(api, output) }.to_h
              operation = {
                'operationId' => endpoint.name.to_s,
                'description' => '',
                'parameters' => parameters,
                'responses' => responses
              }
              operation['requestBody'] = input(api, endpoint.input.type) if endpoint.input
              hash[endpoint.path] ||= {}
              hash[endpoint.path][endpoint.method.to_s] = operation
            end
            hash
          end

          def path_parameter(api, name, type)
            {
              'in' => 'path',
              'name' => name.to_s,
              'required' => true,
              'schema' => schema(api, type)
            }
          end

          def query_parameter(api, name, type)
            optional = type.is_a?(Apigen::OptionalType)
            actual_type = optional ? type.type : type
            {
              'in' => 'query',
              'name' => name.to_s,
              'required' => !optional,
              'schema' => schema(api, actual_type)
            }
          end

          def input(api, type)
            {
              'required' => true,
              'content' => {
                'application/json' => {
                  'schema' => schema(api, type)
                }
              }
            }
          end

          def response(api, output)
            response = {}
            response['description'] = ''
            if output.type != :void
              response['content'] = {
                'application/json' => {
                  'schema' => schema(api, output.type)
                }
              }
            end
            [output.status.to_s, response]
          end

          def definitions(api)
            hash = {}
            api.models.each do |key, model|
              hash[key.to_s] = schema(api, model.type)
            end
            hash
          end

          def schema(api, type)
            case type
            when Apigen::ObjectType
              object_schema(api, type)
            when Apigen::ArrayType
              array_schema(api, type)
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

          def object_schema(api, object_type)
            {
              'type' => 'object',
              'properties' => object_type.properties.map { |name, type| object_property(api, name, type) }.to_h,
              'required' => object_type.properties.reject { |_name, type| type.is_a? Apigen::OptionalType }.map { |name, _type| name.to_s }
            }
          end

          def object_property(api, name, type)
            # A property is never optional, because we specify which are required on the schema itself.
            actual_type = type.is_a?(Apigen::OptionalType) ? type.type : type
            [name.to_s, schema(api, actual_type)]
          end

          def array_schema(api, array_type)
            {
              'type' => 'array',
              'items' => schema(api, array_type.type)
            }
          end
        end
      end
    end
  end
end
