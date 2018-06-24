# frozen_string_literal: true

require 'set'
require_relative './util'

module Apigen
  PRIMARY_TYPES = Set.new %i[string int32 bool void]

  ##
  # ModelRegistry is where all model definitions are stored.
  class ModelRegistry
    attr_reader :models

    def initialize
      @models = {}
    end

    def model(name, &block)
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
      if type.is_a? Symbol
        raise "Unknown type :#{type}." unless @models.key?(type) || PRIMARY_TYPES.include?(type)
      elsif type.is_a?(ObjectType) || type.is_a?(ArrayType) || type.is_a?(OptionalType)
        type.validate self
      else
        raise "Cannot process type #{type.class.name}"
      end
    end

    def to_s
      @models.map do |key, model|
        "#{key}: #{model}"
      end.join "\n"
    end
  end

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
      if shape.to_s.end_with? '?'
        shape = shape[0..-2].to_sym
        optional = true
      else
        optional = false
      end
      case shape
      when :object
        object = ObjectType.new
        object.instance_eval(&block)
        type = object
      when :array
        array = ArrayType.new
        array.instance_eval(&block)
        type = array
      when :optional
        optional = OptionalType.new
        optional.instance_eval(&block)
        type = optional
      else
        type = shape
      end
      optional ? OptionalType.new(type) : type
    end

    def validate(model_registry)
      raise 'One of the models is missing a name.' unless @name
      raise "Use `type :model_type [block]` to assign a type to :#{@name}." unless @type
      model_registry.check_type @type
    end

    def to_s
      @type.to_s
    end
  end

  ##
  # ObjectType represents an object type, with specific properties.
  class ObjectType
    attr_reader :properties

    def initialize
      @properties = {}
    end

    # rubocop:disable Style/MethodMissingSuper
    def method_missing(property_name, *args, &block)
      raise "Property :#{property_name} is defined multiple times." if @properties.key? property_name
      property_type = args[0]
      property_description = args[1]
      block_called = false
      if block_given?
        block_wrapper = lambda do
          block_called = true
          yield
        end
      end
      property = ObjectProperty.new(
        Apigen::Model.type(property_type, &block_wrapper),
        property_description
      )
      property.instance_eval(&block) if block_given? && !block_called
      @properties[property_name] = property
    end
    # rubocop:enable Style/MethodMissingSuper

    def respond_to_missing?(_method_name, _include_private = false)
      true
    end

    def validate(model_registry)
      @properties.each do |_key, property|
        model_registry.check_type property.type
      end
    end

    def to_s
      repr ''
    end

    def repr(indent)
      repr = '{'
      @properties.each do |key, property|
        type_repr = if property.type.respond_to? :repr
                      property.type.repr(indent + '  ')
                    else
                      property.type.to_s
                    end
        repr += "\n#{indent}  #{key}: #{type_repr}"
      end
      repr += "\n#{indent}}"
      repr
    end
  end

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

  ##
  # ArrayType represents an array type, with a given item type.
  class ArrayType
    def initialize(type = nil)
      @type = type
    end

    def type(item_type = nil, &block)
      return @type unless item_type
      @type = Apigen::Model.type item_type, &block
    end

    def validate(model_registry)
      raise 'Use `type [typename]` to specify the type of types in an array.' unless @type
      model_registry.check_type @type
    end

    def to_s
      repr ''
    end

    def repr(indent)
      type_repr = if @type.respond_to? :repr
                    @type.repr indent
                  else
                    @type.to_s
                  end
      "ArrayType<#{type_repr}>"
    end
  end

  ##
  # OptionalType represents a type whose value may be absent.
  class OptionalType
    def initialize(type = nil)
      @type = type
    end

    def type(item_type = nil, &block)
      return @type unless item_type
      @type = Apigen::Model.type item_type, &block
    end

    def validate(model_registry)
      raise 'Use `type [typename]` to specify an optional type.' unless @type
      model_registry.check_type @type
    end

    def to_s
      repr ''
    end

    def repr(indent)
      type_repr = if @type.respond_to? :repr
                    @type.repr indent
                  else
                    @type.to_s
                  end
      "OptionalType<#{type_repr}>"
    end
  end
end
