require 'yaml'

module Apigen
  module Formats
    module Swagger
      def self.generate api
        # TODO: Allow overriding any of the hardcoded elements.
        {
          "swagger" => "2.0",
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
          "host" => "localhost",
          "basePath" => "/",
          "schemes" => [
            "http",
            "https",
          ],
          "consumes" => [
            "application/json",
          ],
          "produces" => [
            "application/json",
          ],
          "paths" => self.paths(api),
          "definitions" => self.definitions(api),
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
            }.merge(self.type(api, v))
          end
          if endpoint.input
            parameters << {
              "name" => "input",
              "in" => "body",
              "required" => true,
              "schema" => self.type(api, endpoint.input),
            }
          end
          responses = {}
          for output in endpoint.outputs
            response = {
              "description" => "",
            }
            if output.type != :void
              response["schema"] = self.type(api, output.type)
            end
            responses[output.status.to_s] = response
          end
          hash[endpoint.path] = (hash.key?(endpoint.path) ? hash[endpoint.path] : {}).merge({
            endpoint.method.to_s => {
              "description" => "",
              "parameters" => parameters,
              "responses" => responses,
            },
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
          return { "$ref" => "#/definitions/#{type.to_s}" } if api.models.key? type
          raise "Unsupported type: #{type}."
        end
      end
    end
  end
end
