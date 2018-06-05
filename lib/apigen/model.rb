require './lib/apigen/util'

module Apigen
  class ModelRegistry
    def initialize
      @models = {}
    end

    def model name, &block
      model = Apigen::Model.new name
      model.instance_eval &block
      raise "Use `name :model_name` to declare each model." unless model.name
      @models[model.name] = model
    end

    def validate
      @models.each do |key, model|
        model.validate self
      end
    end

    def check_type type
      if type.is_a? Symbol
        case type
        when :string, :int32, :bool, :void
          # Valid.
        else
          if not @models.key? type
            raise "Unknown type :#{type}."
          end
        end
      elsif type.is_a? Object or type.is_a? Array or type.is_a? Optional
        type.validate self
      else
        raise "Cannot process type for key :#{key}"
      end
    end

    def to_s
      @models.map { |key, model|
        "#{key}: #{model}"
      }.join "\n"
    end
  end

  class Model
    attribute_setter_getter :name

    def initialize name
      @name = name
      @type = nil
    end

    def type shape, &block
      @type = Model.type shape, &block
    end

    def self.type shape, &block
      if shape.to_s.end_with? "?"
        shape = shape[0..-2].to_sym
        optional = true
      else
        optional = false
      end
      case shape
      when :object
        object = Object.new
        object.instance_eval &block
        type = object
      when :array
        array = Array.new
        array.instance_eval &block
        type = array
      when :optional
        optional = Optional.new
        optional.instance_eval &block
        type = optional
      else
        type = shape
      end
      if optional
        optional_type = Optional.new
        optional_type.type type
        optional_type
      else
        type
      end
    end

    def validate model_registry
      raise "One of the models is missing a name." unless @name
      raise "Use `type :model_type [block]` to assign a type to :#{@name}." unless @type
      model_registry.check_type @type
    end

    def to_s
      @type.to_s
    end
  end

  class Object
    attr_reader :fields

    def initialize
      @fields = {}
    end

    def method_missing field_name, *args, &block
      raise "Field :#{field_name} is defined multiple times." unless not @fields.key? field_name
      field_type = args[0]
      @fields[field_name] = Apigen::Model.type field_type, &block
    end

    def validate model_registry
      @fields.each do |key, type|
        model_registry.check_type type
      end
    end

    def to_s
      repr ""
    end

    def repr indent
      repr = "{"
      @fields.each do |key, type|
        if type.respond_to? :repr
          type_repr = type.repr (indent + "  ")
        else
          type_repr = type.to_s
        end
        repr += "\n#{indent}  #{key}: #{type_repr}"
      end
      repr += "\n#{indent}}"
      repr
    end
  end

  class Array
    attr_reader :item

    def initialize
      @item = nil
    end

    def item item_type, &block
      @item = Apigen::Model.type item_type, &block
    end

    def validate model_registry
      raise "Use `item [typename]` to specify the type of items in an array." unless @item
      model_registry.check_type @item
    end

    def to_s
      repr ""
    end

    def repr indent
      if @item.respond_to? :repr
        item_repr = @item.repr indent
      else
        item_repr = @item.to_s
      end
      "Array<#{item_repr}>"
    end
  end

  class Optional
    attr_reader :type

    def initialize
      @type = nil
    end

    def type item_type, &block
      @type = Apigen::Model.type item_type, &block
    end

    def validate model_registry
      raise "Use `type [typename]` to specify an optional type." unless @type
      model_registry.check_type @type
    end

    def to_s
      repr ""
    end

    def repr indent
      if @type.respond_to? :repr
        type_repr = @type.repr indent
      else
        type_repr = @type.to_s
      end
      "Optional<#{type_repr}>"
    end
  end
end
