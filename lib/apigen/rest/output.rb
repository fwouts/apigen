# frozen_string_literal: true

module Apigen
  module Rest
    ##
    # Output is the response type associated with a specific status code for an API endpoint.
    class Output
      attr_reader :name
      attribute_setter_getter :status
      attribute_setter_getter :description
      attribute_setter_getter :example

      def initialize(name)
        @name = name
        @status = nil
        @type = nil
        @description = nil
      end

      ##
      # Declares the output type.
      def type(type = nil, &block)
        return @type unless type
        @type = Apigen::Model.type type, &block
      end

      def validate(model_registry)
        validate_properties
        model_registry.check_type @type
      end

      def to_s
        "#{@name} #{@status} #{@type}"
      end

      private

      def validate_properties
        error = if !@name
                  'One of the outputs is missing a name.'
                elsif !@status
                  "Use `status [code]` to assign a status code to :#{@name}."
                elsif !@status
                  "Use `type :typename` to assign a type to :#{@name}."
                end
        raise error unless error.nil?
      end
    end
  end
end
