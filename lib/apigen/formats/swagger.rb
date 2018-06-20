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
                'description' => api.description,
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
              parameters.concat(endpoint.path_parameters.properties.map { |name, property| path_parameter(api, name, property) })
              parameters.concat(endpoint.query_parameters.properties.map { |name, property| query_parameter(api, name, property) })
              parameters << input_parameter(api, endpoint.input) if endpoint.input
              responses = endpoint.outputs.map { |output| response(api, output) }.to_h
              hash[endpoint.path] ||= {}
              hash[endpoint.path][endpoint.method.to_s] = {
                'parameters' => parameters,
                'responses' => responses
              }
              hash[endpoint.path][endpoint.method.to_s]['description'] = endpoint.description unless endpoint.description.nil?
            end
            hash
          end

          def path_parameter(api, name, property)
            {
              'in' => 'path',
              'name' => name.to_s,
              'required' => true
            }.merge(schema(api, property.type, property.description, property.example))
          end

          def query_parameter(api, name, property)
            optional = property.type.is_a?(Apigen::OptionalType)
            actual_type = optional ? property.type.type : property.type
            {
              'in' => 'query',
              'name' => name.to_s,
              'required' => !optional
            }.merge(schema(api, actual_type, property.description, property.example))
          end

          def input_parameter(api, property)
            parameter = {
              'name' => 'input',
              'in' => 'body',
              'required' => true,
              'schema' => schema(api, property.type)
            }
            parameter['description'] = property.description unless property.description.nil?
            parameter['example'] = property.example unless property.example.nil?
            parameter
          end

          def response(api, output)
            response = {}
            response['description'] = output.description unless output.description.nil?
            response['example'] = output.example unless output.example.nil?
            response['schema'] = schema(api, output.type) if output.type != :void
            [output.status.to_s, response]
          end

          def definitions(api)
            api.models.map { |key, model| [key.to_s, schema(api, model.type, model.description, model.example)] }.to_h
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
        end
      end
    end
  end
end
