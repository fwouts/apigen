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
            definitions(api).to_json
          end

          private

          def definitions(api)
            {
              '$schema' => 'http://json-schema.org/draft-07/schema#',
              'definitions' => api.models.map { |key, model| [key.to_s, schema(api, model.type)] }.to_h
            }
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
              return { '$ref' => "#/definitions/#{type}" } if api.models.key? type
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
