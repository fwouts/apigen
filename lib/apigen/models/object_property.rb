# frozen_string_literal: true

require_relative '../util'

module Apigen
  ##
  # ObjectProperty is a specific property in an ObjectType.
  class ObjectProperty
    attr_reader :type
    attr_writer :required
    attribute_setter_getter :description
    attribute_setter_getter :example

    def initialize(type, description = nil)
      @type = type
      @description = description
      @required = true
    end

    def required(required)
      @required = required
      self
    end

    def required?
      @required
    end

    def ==(other)
      other.is_a?(ObjectProperty) && type == other.type && required? == other.required? && description == other.description && example == other.example
    end
  end
end
