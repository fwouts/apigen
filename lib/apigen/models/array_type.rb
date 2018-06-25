# frozen_string_literal: true

module Apigen
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
      raise 'Use `type [typename]` to specify the type of items in an array.' unless @type
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
end
