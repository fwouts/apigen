require 'yaml'

module Apigen
  module Formats
    module OpenAPI
      module V3
        def self.generate api
          # TODO: Allow overriding any of the hardcoded elements.
          {
            "openapi" => "3.0.0",
            "info" => {
              "version" => "1.0.0",
              "title" => "API",
              "description" => "",
              "termsOfService" => "",
              "contact" => {
                "name" => "",
              },
              "license" => {
                "name" => "",
              },
            },
            "servers" => [
              {
                "url" => "http://localhost"
              },
            ],
            "paths" => self.paths(api),
            "components" => {
              "schemas" => self.definitions(api),
            },
          }.to_yaml
        end

        private

        def self.paths api
          hash = {}
          for endpoint in api.endpoints
            parameters = []
            endpoint.path_parameters.properties.each do |k, v|
              parameters << {
                "in" => "path",
                "name" => k.to_s,
                "required" => true,
                "schema" => self.type(api, v),
              }
            end
            responses = {}
            for output in endpoint.outputs
              response = {
                "description" => "",
              }
              if output.type != :void
                response["content"] = {
                  "application/json" => {
                    "schema" => self.type(api, output.type),
                  },
                }
              end
              responses[output.status.to_s] = response
            end
            operation = {
              "operationId" => endpoint.name.to_s,
              "description" => "",
              "parameters" => parameters,
              "responses" => responses,
            }
            if endpoint.input
              operation["requestBody"] = {
                "required" => true,
                "content" => {
                  "application/json" => {
                    "schema" => self.type(api, endpoint.input),
                  },
                },
              }
            end
            hash[endpoint.path] = (hash.key?(endpoint.path) ? hash[endpoint.path] : {}).merge({
              endpoint.method.to_s => operation,
            })
          end
          hash
        end

        def self.definitions api
          hash = {}
          api.models.each do |key, model|
            hash[key.to_s] = self.type api, model.type
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
              "type" => "integer",
              "format" => "int32",
            }
          else
            return { "$ref" => "#/components/schemas/#{type.to_s}" } if api.models.key? type
            raise "Unsupported type: #{type}."
          end
        end
      end
    end
  end
end
