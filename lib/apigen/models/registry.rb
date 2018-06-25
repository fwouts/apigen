# frozen_string_literal: true

require_relative './model'
require_relative './primary_types'

module Apigen
  ##
  # ModelRegistry is where all model definitions are stored.
  class ModelRegistry
    attr_reader :models

    def initialize
      @models = {}
    end

    def model(name, &block)
      raise "Model :#{name} is declared twice." if @models.key? name
      model = Apigen::Model.new name
      raise 'You must pass a block when calling `model`.' unless block_given?
      model.instance_eval(&block)
      @models[model.name] = model
    end

    def validate
      @models.each do |_key, model|
        model.validate self
      end
    end

    def check_type(type)
      if complex_type?(type)
        type.validate self
      else
        unless primary_type?(type) || reference_type?(type)
          raise "Unknown type :#{type}."
        end
      end
    end

    def to_s
      @models.map do |key, model|
        "#{key}: #{model}"
      end.join "\n"
    end

    private

    def complex_type?(type)
      type.is_a?(ObjectType) || type.is_a?(ArrayType) || type.is_a?(OptionalType)
    end

    def primary_type?(type)
      Apigen::PRIMARY_TYPES.include?(type)
    end

    def reference_type?(type)
      @models.key?(type)
    end
  end
end
