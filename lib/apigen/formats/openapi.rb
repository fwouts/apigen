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
                'description' => api.description,
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
              parameters.concat(endpoint.path_parameters.properties.map { |name, property| path_parameter(api, name, property) })
              parameters.concat(endpoint.query_parameters.properties.map { |name, property| query_parameter(api, name, property) })
              responses = endpoint.outputs.map { |output| response(api, output) }.to_h
              operation = {
                'operationId' => endpoint.name.to_s,
                'parameters' => parameters,
                'responses' => responses
              }
              operation['description'] = endpoint.description unless endpoint.description.nil?
              operation['requestBody'] = input(api, endpoint.input) if endpoint.input
              hash[endpoint.path] ||= {}
              hash[endpoint.path][endpoint.method.to_s] = operation
            end
            hash
          end

          def path_parameter(api, name, property)
            parameter = {
              'in' => 'path',
              'name' => name.to_s,
              'required' => true,
              'schema' => schema(api, property.type)
            }
            parameter['description'] = property.description unless property.description.nil?
            parameter['example'] = property.example unless property.example.nil?
            parameter
          end

          def query_parameter(api, name, property)
            optional = property.type.is_a?(Apigen::OptionalType)
            actual_type = optional ? property.type.type : property.type
            parameter = {
              'in' => 'query',
              'name' => name.to_s,
              'required' => !optional,
              'schema' => schema(api, actual_type)
            }
            parameter['description'] = property.description unless property.description.nil?
            parameter['example'] = property.example unless property.example.nil?
            parameter
          end

          def input(api, property)
            parameter = {
              'required' => true,
              'content' => {
                'application/json' => {
                  'schema' => schema(api, property.type)
                }
              }
            }
            parameter['description'] = property.description unless property.description.nil?
            parameter['example'] = property.example unless property.example.nil?
            parameter
          end

          def response(api, output)
            response = {}
            response['description'] = output.description unless output.description.nil?
            response['example'] = output.example unless output.example.nil?
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
              hash[key.to_s] = schema(api, model.type, model.description, model.example)
            end
            hash
          end

          def schema(api, type, description = nil, example = nil)
            schema = schema_without_description(api, type)
            schema['description'] = description unless description.nil?
            schema['example'] = example unless example.nil?
            schema
          end

          def schema_without_description(api, type)
            case type
            when Apigen::ObjectType
              object_schema(api, type)
            when Apigen::ArrayType
              array_schema(api, type)
            when Apigen::OptionalType
              raise 'Optional types are only supported within object types.'
            when Apigen::OneofType
              oneof_schema(api, type)
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
              'properties' => object_type.properties.map { |name, property| object_property(api, name, property) }.to_h,
              'required' => object_type.properties.reject { |_name, property| property.type.is_a? Apigen::OptionalType }.map { |name, _property| name.to_s }
            }
          end

          def object_property(api, name, property)
            # A property is never optional, because we specify which are required on the schema itself.
            actual_type = property.type.is_a?(Apigen::OptionalType) ? property.type.type : property.type
            [name.to_s, schema(api, actual_type, property.description, property.example)]
          end

          def array_schema(api, array_type)
            {
              'type' => 'array',
              'items' => schema(api, array_type.type)
            }
          end

          def oneof_schema(_api, oneof_type)
            schema = {
              'oneOf' => oneof_type.mapping.keys.map { |model_name| { '$ref' => "#/components/schemas/#{model_name}" } }
            }
            if oneof_type.discriminator
              schema['discriminator'] = {
                'propertyName' => oneof_type.discriminator.to_s,
                'mapping' => oneof_type.mapping.map { |model_name, disc_value| [disc_value, "#/components/schemas/#{model_name}"] }.to_h
              }
            end
            schema
          end
        end
      end
    end
  end
end
