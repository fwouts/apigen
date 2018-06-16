require 'json'

module Apigen
  module Formats
    module JsonSchema
      module Draft7
        def self.generate api
          self.definitions(api).to_json
        end

        private

        def self.definitions api
          hash = {
            "$schema" => "http://json-schema.org/draft-07/schema#",
            "definitions" => {},
          }
          api.models.each do |key, model|
            hash["definitions"][key.to_s] = self.type api, model.type
          end
          hash
        end

        def self.type api, type
          case type
          when Apigen::Object
            required_fields = []
            type.properties.each do |k, v|
              required_fields << k.to_s if not v.is_a? Apigen::Optional
            end
            return {
              "type" => "object",
              "properties" => type.properties.map { |k, v|
                # We're already reflecting the fact that fields are optional with required fields.
                property_type = v.is_a?(Apigen::Optional) ? v.type : v
                [k.to_s, self.type(api, property_type)]
              }.to_h,
              "required" => required_fields,
            }
          when Apigen::Array
            return {
              "type" => "array",
              "items" => self.type(api, type.type),
            }
          when Apigen::Optional
            raise "Optional fields are only supported within object types."
          when :string
            return {
              "type" => "string",
            }
          when :int32
            return {
              "type" => "integer",
              "format" => "int32",
            }
          when :bool
            return {
              "type" => "boolean",
            }
          else
            return { "$ref" => "#/definitions/#{type.to_s}" } if api.models.key? type
            raise "Unsupported type: #{type}."
          end
        end
      end
    end
  end
end
