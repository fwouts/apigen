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
        raise 'Mapping keys must be model names (use symbols).' unless key.is_a? Symbol
        raise 'Mapping values must be strings.' unless value.is_a? String
        raise "No such model :#{key} for oneof mapping." unless model_registry.models.key? key
      end
    end
  end
end
