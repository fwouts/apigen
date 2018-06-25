# frozen_string_literal: true

require 'set'

module Apigen
  ##
  # PrimaryType represents a primary type such as a string or an integer.
  class PrimaryType
    PRIMARY_TYPES = Set.new %i[string int32 bool void]

    def self.primary?(shape)
      PRIMARY_TYPES.include? shape
    end

    attr_reader :shape

    def initialize(shape)
      @shape = shape
    end

    def validate(_model_registry)
      raise "Unsupported primary type :#{@shape}." unless self.class.primary?(@shape)
    end

    def ==(other)
      other.is_a?(PrimaryType) && other.shape == shape
    end

    def to_s
      @shape.to_s
    end
  end
end
