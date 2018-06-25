# frozen_string_literal: true

require 'json'
require_relative './json_base'

module Apigen
  module Formats
    module JsonSchema
      ##
      # JSON Schema Draft 7 generator.
      module Draft7
        class << self
          include Apigen::Formats::JsonBase

          def generate(api)
            JSON.pretty_generate(
              '$schema' => 'http://json-schema.org/draft-07/schema#',
              'definitions' => definitions(api)
            )
          end

          private

          def model_ref(type)
            "#/definitions/#{type}"
          end

          def supports_discriminator?
            false
          end
        end
      end
    end
  end
end
