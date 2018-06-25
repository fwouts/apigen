# frozen_string_literal: true

require_relative '../util'

module Apigen
  ##
  # OneofType represents a union type, aka "either or".
  class OneofType
    ##
    # The discriminator tells us which property defines the type of the object.
    #
    # Setting a discriminator is optional, but recommended.
    attribute_setter_getter :discriminator
    attr_reader :mapping

    def initialize
      @discriminator = nil
      @mapping = {}
    end

    def map(mapping)
      @mapping = mapping
    end

    def validate(model_registry)
      @mapping.each do |key, value|
        validate_mapping_item(model_registry, key, value)
      end
    end

    private

    def validate_mapping_item(model_registry, key, value)
      error = if !(key.is_a? Symbol)
                'Mapping keys must be model names (use symbols).'
              elsif !(value.is_a? String)
                'Mapping values must be strings.'
              elsif !(model_registry.models.key? key)
                "No such model :#{key} for oneof mapping."
              end
      raise error unless error.nil?
    end
  end
end
