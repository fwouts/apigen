# frozen_string_literal: true

require './lib/apigen/util'

module Apigen
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
        case type
        # rubocop:disable Lint/EmptyWhen
        when :string, :int32, :bool, :void
        else
          # rubocop:enable Lint/EmptyWhen
          raise "Unknown type :#{type}." unless @models.key? type
        end
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

    def initialize(name)
      @name = name
      @type = nil
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
      if optional
        optional_type = OptionalType.new
        optional_type.type type
        optional_type
      else
        type
      end
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
  # ObjectType represents an object type, with specific fields.
  class ObjectType
    attr_reader :properties

    def initialize
      @properties = {}
    end

    # rubocop:disable Style/MethodMissingSuper
    def method_missing(field_name, *args, &block)
      raise "Field :#{field_name} is defined multiple times." if @properties.key? field_name
      field_type = args[0]
      @properties[field_name] = Apigen::Model.type field_type, &block
    end
    # rubocop:enable Style/MethodMissingSuper

    def respond_to_missing?(_method_name, _include_private = false)
      true
    end

    def validate(model_registry)
      @properties.each do |_key, type|
        model_registry.check_type type
      end
    end

    def to_s
      repr ''
    end

    def repr(indent)
      repr = '{'
      @properties.each do |key, type|
        type_repr = if type.respond_to? :repr
                      type.repr(indent + '  ')
                    else
                      type.to_s
                    end
        repr += "\n#{indent}  #{key}: #{type_repr}"
      end
      repr += "\n#{indent}}"
      repr
    end
  end

  ##
  # ArrayType represents an array type, with a given item type.
  class ArrayType
    def initialize
      @type = nil
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
    def initialize
      @type = nil
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
