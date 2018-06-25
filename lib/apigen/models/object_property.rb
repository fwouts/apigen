# frozen_string_literal: true

require_relative '../util'

module Apigen
  ##
  # ObjectProperty is a specific property in an ObjectType.
  class ObjectProperty
    attr_reader :type
    attribute_setter_getter :description
    attribute_setter_getter :example

    def initialize(type, description = nil)
      @type = type
      @description = description
    end
  end
end
