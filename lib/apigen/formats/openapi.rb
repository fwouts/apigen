# frozen_string_literal: true

require 'yaml'
require_relative './json_base'

module Apigen
  module Formats
    module OpenAPI
      ##
      # OpenAPI 3 generator.
      module V3
        class << self
          include Apigen::Formats::JsonBase

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
            parameter = {
              'in' => 'query',
              'name' => name.to_s,
              'required' => property.required?,
              'schema' => schema(api, property.type)
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
            if output.type != Apigen::PrimaryType.new(:void)
              response['content'] = {
                'application/json' => {
                  'schema' => schema(api, output.type)
                }
              }
            end
            [output.status.to_s, response]
          end

          def model_ref(type)
            "#/components/schemas/#{type}"
          end

          def supports_discriminator?
            true
          end
        end
      end
    end
  end
end
