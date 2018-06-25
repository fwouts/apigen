# frozen_string_literal: true

require_relative '../util'

module Apigen
  ##
  # EnumType represents an enum (a type that can be one of several constants).
  class EnumType
    attr_reader :values

    def initialize
      @values = []
    end

    def value(val)
      @values << val
    end

    def validate(_model_registry)
      @values.each do |val|
        raise 'Enums only support string values' unless val.is_a? String
      end
    end
  end
end
