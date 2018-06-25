# frozen_string_literal: true

require 'yaml'
require_relative './json_base'

module Apigen
  module Formats
    module Swagger
      ##
      # Swagger 2 (aka OpenAPI 2) generator.
      module V2
        class << self
          include Apigen::Formats::JsonBase

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
            {
              'in' => 'query',
              'name' => name.to_s,
              'required' => property.required?
            }.merge(schema(api, property.type, property.description, property.example))
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
            response['schema'] = schema(api, output.type) if output.type != Apigen::PrimaryType.new(:void)
            [output.status.to_s, response]
          end

          def model_ref(type)
            "#/definitions/#{type}"
          end

          def supports_discriminator?
            true
          end
        end
      end
    end
  end
end
