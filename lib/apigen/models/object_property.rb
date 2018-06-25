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

    def initialize(type, description = nil, example = nil)
      @type = type
      @description = description
      @example = example
      @required = true
    end

    def required(required)
      @required = required
      self
    end

    def required?
      @required
    end

    def explain(&block)
      raise 'You must pass a block to `explain`.' unless block_given?
      instance_eval(&block)
    end

    def ==(other)
      other.is_a?(ObjectProperty) && type == other.type && required? == other.required? && description == other.description && example == other.example
    end
  end
end
