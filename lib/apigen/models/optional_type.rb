# frozen_string_literal: true

require_relative '../util'

module Apigen
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
