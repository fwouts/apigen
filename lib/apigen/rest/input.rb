# frozen_string_literal: true

module Apigen
  module Rest
    ##
    # Input is the request body expected by an API endpoint.
    class Input
      attribute_setter_getter :description
      attribute_setter_getter :example

      def initialize
        @type = nil
        @description = nil
      end

      ##
      # Declares the input type.
      def type(type = nil, &block)
        return @type unless type
        @type = Apigen::Model.type type, &block
      end

      def validate(model_registry)
        validate_properties
        model_registry.check_type @type
      end

      def to_s
        @type.to_s
      end

      private

      def validate_properties
        raise 'Use `type :typename` to assign a type to the input.' unless @type
      end
    end
  end
end
