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
              {
                'type' => 'object',
                'properties' => type.properties.map { |n, t| property(api, n, t) }.to_h,
                'required' => type.properties.reject { |_, t| t.is_a? Apigen::OptionalType }.map { |n, _| n.to_s }
              }
            when Apigen::ArrayType
              {
                'type' => 'array',
                'items' => schema(api, type.type)
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

          def property(api, name, type)
            # A property is never optional, because we specify which are required on the schema itself.
            actual_type = type.is_a?(Apigen::OptionalType) ? type.type : type
            [name.to_s, schema(api, actual_type)]
          end
        end
      end
    end
  end
end
