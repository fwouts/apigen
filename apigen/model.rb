require './apigen/util'

module Apigen
  class ModelRegistry
    attr_reader :models

    def initialize
      @models = {}
    end

    def model(&block)
      model = Apigen::Model.new
      model.instance_eval &block
      raise "Use `name :model_name` to declare each model." unless model.name
      @models[model.name] = model
    end

    def validate
      @models.each do |key, model|
        model.validate self
      end
    end

    def to_s
      @models.map { |key, model|
        "#{key}: #{model.repr}"
      }.join "\n"
    end
  end

  class Model
    attribute_setter_getter :name

    def initialize
      @name = nil
      @type = nil
    end

    def type(shape, &block)
      case shape
      when :struct
        struct = Struct.new
        struct.instance_eval &block
        @type = struct
      when :list
        list = List.new
        list.instance_eval &block
        @type = list
      when :optional
        optional = Optional.new
        optional.instance_eval &block
        @type = optional
      else
        raise "Unknown model type: #{shape}."
      end
    end

    def validate(model_registry)
      raise "Use `name :model_name` to declare each model." unless @name
      raise "Use `type :model_type [block]` to assign a type to :#{@name}." unless @type
      @type.validate model_registry
    end

    def repr(indent = "")
      @type.repr indent
    end

    class Struct
      def initialize
        @fields = {}
      end

      def method_missing(field_name, *args, &block)
        raise "Field :#{field_name} is defined multiple times." unless not @fields.key? field_name
        field_type = args[0]
        if block_given?
          field_model = Apigen::Model.new
          field_model.name "#{@name}.#{field_name}".to_sym
          field_model.type field_type, &block
          @fields[field_name] = field_model
        else
          @fields[field_name] = field_type
        end
      end

      def validate(model_registry)
        @fields.each do |key, type|
          if type.is_a? Symbol
            case type
            when :string, :int32, :bool
              # Valid.
            else
              if not model_registry.models.key? type
                raise "Unknown type :#{type}."
              end
            end
          elsif type.is_a? Model
            type.validate model_registry
          else
            raise "Cannot process type for key :#{key}"
          end
        end
      end

      def repr(indent)
        repr = "{"
        @fields.each do |key, type|
          if type.is_a? Model
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

    class List
      def initialize
        @item = nil
      end

      def item(item_type, &block)
        if block_given?
          item_model = Apigen::Model.new
          item_model.name "#{@name}.item".to_sym
          item_model.type item_type, &block
          @item = item_model
        else
          @item = item_type
        end
      end

      def validate(model_registry)
        raise "Use `item [typename]` to specify the type of items in a list." unless @item
        if @item.is_a? Model
          @item.validate model_registry
        end
      end

      def repr(indent)
        if @item.is_a? Model
          item_repr = @item.repr indent
        else
          item_repr = @item.to_s
        end
        "List<#{item_repr}>"
      end
    end

    class Optional
      def initialize
        @type = nil
      end

      def type(item_type, &block)
        if block_given?
          item_model = Apigen::Model.new
          item_model.name "#{@name}.item".to_sym
          item_model.type item_type, &block
          @type = item_model
        else
          @type = item_type
        end
      end

      def validate(model_registry)
        raise "Use `type [typename]` to specify an optional type." unless @type
        if @type.is_a? Model
          @type.validate model_registry
        end
      end

      def repr(indent)
        if @type.is_a? Model
          type_repr = @type.repr indent
        else
          type_repr = @type.to_s
        end
        "Optional<#{type_repr}>"
      end
    end
  end
end
