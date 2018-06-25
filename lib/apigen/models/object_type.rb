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
    def method_missing(property_name, *args, &block)
      raise "Property :#{property_name} is defined multiple times." if @properties.key? property_name
      property_type = args[0]
      property_description = args[1]
      block_called = false
      if block_given?
        block_wrapper = lambda do
          block_called = true
          yield
        end
      end
      if property_type.to_s.end_with? '?'
        property_type = property_type[0..-2].to_sym
        required = false
      else
        required = true
      end
      property = ObjectProperty.new(
        Apigen::Model.type(property_type, &block_wrapper),
        property_description
      )
      property.instance_eval(&block) if block_given? && !block_called
      property.required = required
      @properties[property_name] = property
    end
    # rubocop:enable Style/MethodMissingSuper

    def respond_to_missing?(_method_name, _include_private = false)
      true
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
        type_repr = if property.type.respond_to? :repr
                      property.type.repr(indent + '  ')
                    else
                      property.type.to_s
                    end
        repr += "\n#{indent}  #{key}: #{type_repr}"
      end
      repr += "\n#{indent}}"
      repr
    end
  end
end
