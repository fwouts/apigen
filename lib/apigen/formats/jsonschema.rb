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
            hash = {
              '$schema' => 'http://json-schema.org/draft-07/schema#',
              'definitions' => {}
            }
            api.models.each do |key, model|
              hash['definitions'][key.to_s] = type api, model.type
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
