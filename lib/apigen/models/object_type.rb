# frozen_string_literal: true

require_relative '../util'
require_relative './object_property'

module Apigen
  ##
  # ObjectType represents an object type, with specific properties.
  class ObjectType
    attr_reader :properties

    def initialize
      @properties = {}
    end

    def add(&block)
      instance_eval(&block)
    end

    def remove(*property_names)
      property_names.each do |property_name|
        raise "Cannot remove nonexistent property :#{property_name}." unless @properties.delete(property_name)
      end
    end

    # rubocop:disable Style/MethodMissingSuper
    def method_missing(*args, &block)
      property(*args, &block)
    end
    # rubocop:enable Style/MethodMissingSuper

    def respond_to_missing?(_method_name, _include_private = false)
      true
    end

    def property(property_name, property_shape, &block)
      ensure_correctness(property_name, property_shape)
      if property_shape.to_s.end_with? '?'
        property_shape = property_shape[0..-2].to_sym
        required = false
      else
        required = true
      end
      property = ObjectProperty.new(Apigen::Model.type(property_shape, &block))
      property.required = required
      @properties[property_name] = property
    end

    def validate(model_registry)
      @properties.each do |_key, property|
        model_registry.check_type property.type
      end
    end

    def to_s
      repr ''
    end

    def repr(indent)
      repr = '{'
      @properties.each do |key, property|
        repr += "\n#{indent}  #{property_repr(indent, key, property)}"
      end
      repr += "\n#{indent}}"
      repr
    end

    private

    def ensure_correctness(property_name, property_shape)
      error = if @properties.key? property_name
                "Property :#{property_name} is defined multiple times."
              elsif !property_shape.is_a? Symbol
                "Property type must be a symbol, found #{property_shape}."
              end
      raise error unless error.nil?
    end

    def property_repr(indent, key, property)
      type_repr = if property.type.respond_to? :repr
                    property.type.repr(indent + '  ')
                  else
                    property.type.to_s
                  end
      type_repr += '?' unless property.required?
      "#{key}: #{type_repr}"
    end
  end
end
