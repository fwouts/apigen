# frozen_string_literal: true

module Apigen
  ##
  # Migration is the base class for API definition migrations.
  class Migration
    def initialize(api)
      @api = api
    end

    def up
      raise 'Migration subclasses must implement #up.'
    end

    def add_endpoint(name, &block)
      raise 'You must pass a block when calling `add_endpoint`.' unless block_given?
      @api.endpoint(name, &block)
    end

    def update_endpoint(name, &block)
      endpoint = @api.endpoints.find { |e| e.name == name }
      error = if !endpoint
                "No such endpoint #{name}."
              elsif !block_given?
                'You must pass a block when calling `update_endpoint`.'
              end
      raise error unless error.nil?
      endpoint.instance_eval(&block)
    end

    def remove_endpoint(*names)
      endpoints = @api.endpoints
      # This is not algorithmically optimal. We won't do it millions of times though.
      names.each do |name|
        raise "No such endpoint :#{name}." unless endpoints.find { |e| e.name == name }
      end
      endpoints.reject! { |e| names.include?(e.name) }
    end

    def add_model(name, &block)
      @api.model(name, &block)
    end

    def update_model(name, &block)
      model = @api.models[name]
      error = if !model
                "No such model :#{name}."
              elsif !block_given?
                'You must pass a block when calling `update_model`.'
              end
      raise error unless error.nil?
      model.instance_eval(&block)
    end

    def remove_model(*names)
      models = @api.models
      names.each do |name|
        raise "No such model :#{name}." unless models.key? name
      end
      names.each { |model_name| models.delete(model_name) }
    end
  end
end
