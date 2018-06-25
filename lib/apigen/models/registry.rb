# frozen_string_literal: true

require_relative './model'

module Apigen
  ##
  # ModelRegistry is where all model definitions are stored.
  class ModelRegistry
    attr_reader :models

    def initialize
      @models = {}
    end

    def model(name, &block)
      error = if @models.key? name
                "Model :#{name} is declared twice."
              elsif !block_given?
                'You must pass a block when calling `model`.'
              end
      raise error unless error.nil?
      model = Apigen::Model.new name
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
