# frozen_string_literal: true

require 'json'

module Apigen
  module Formats
    module JsonSchema
      ##
      # JSON Schema Draft 7 generator.
      module Draft7
        class << self
          def generate(api)
            JSON.pretty_generate definitions(api)
          end

          private

          def definitions(api)
            {
              '$schema' => 'http://json-schema.org/draft-07/schema#',
              'definitions' => api.models.map { |key, model| [key.to_s, schema(api, model.type, model.description, model.example)] }.to_h
            }
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
              return { '$ref' => "#/definitions/#{type}" } if api.models.key? type
              raise "Unsupported type: #{type}."
            end
          end

          def object_schema(api, object_type)
            {
              'type' => 'object',
              'properties' => object_type.properties.map { |name, property| object_property(api, name, property) }.to_h,
              'required' => object_type.properties.select { |_name, property| property.required? }.map { |name, _property| name.to_s }
            }
          end

          def object_property(api, name, property)
            [name.to_s, schema(api, property.type, property.description, property.example)]
          end

          def array_schema(api, array_type)
            {
              'type' => 'array',
              'items' => schema(api, array_type.type)
            }
          end

          def oneof_schema(_api, oneof_type)
            # Note: discriminator is not supported by JSON Schema, so we skip it.
            {
              'oneOf' => oneof_type.mapping.keys.map { |model_name| { '$ref' => "#/definitions/#{model_name}" } }
            }
          end
        end
      end
    end
  end
end
