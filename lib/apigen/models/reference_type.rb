# frozen_string_literal: true

require 'set'

module Apigen
  ##
  # ReferenceType represents a reference to a model.
  class ReferenceType
    attr_reader :model_name

    def initialize(model_name)
      @model_name = model_name
    end

    def validate(model_registry)
      raise "Model :#{@model_name} is not defined." unless model_registry.models.key? @model_name
    end

    def ==(other)
      other.is_a?(ReferenceType) && other.model_name == model_name
    end

    def to_s
      @model_name.to_s
    end
  end
end
