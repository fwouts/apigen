# frozen_string_literal: true

require_relative './model'
require_relative './array_type'
require_relative './object_type'
require_relative './primary_type'
require_relative './oneof_type'

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
      type.validate self
    end

    def to_s
      @models.map do |key, model|
        "#{key}: #{model}"
      end.join "\n"
    end
  end
end
