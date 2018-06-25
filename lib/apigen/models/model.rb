# frozen_string_literal: true

require_relative '../util'
require_relative './array_type'
require_relative './object_type'
require_relative './oneof_type'
require_relative './primary_type'
require_relative './reference_type'
require_relative './registry'

module Apigen
  ##
  # Model represents a data model with a specific name, e.g. "User" with an object type.
  class Model
    attr_reader :name
    attribute_setter_getter :description
    attribute_setter_getter :example

    def initialize(name)
      @name = name
      @type = nil
      @description = nil
    end

    def type(shape = nil, &block)
      return @type unless shape
      @type = Model.type shape, &block
    end

    def self.type(shape, &block)
      case shape
      when :object
        object = ObjectType.new
        object.instance_eval(&block)
        object
      when :array
        array = ArrayType.new
        array.instance_eval(&block)
        array
      when :oneof
        oneof = OneofType.new
        oneof.instance_eval(&block)
        oneof
      else
        if PrimaryType.primary?(shape)
          PrimaryType.new(shape)
        else
          ReferenceType.new(shape)
        end
      end
    end

    def validate(model_registry)
      raise 'One of the models is missing a name.' unless @name
      raise "Use `type :model_type [block]` to assign a type to :#{@name}." unless @type
      model_registry.check_type @type
    end

    def update_object_properties(&block)
      raise "#{@name} is not an object type" unless @type.is_a? ObjectType
      @type.instance_eval(&block)
    end

    def to_s
      @type.to_s
    end
  end
end
