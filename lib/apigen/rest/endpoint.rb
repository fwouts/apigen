# frozen_string_literal: true

require_relative './input'
require_relative './output'

module Apigen
  module Rest
    ##
    # Endpoint is a definition of a specific endpoint in the API, e.g. /users with GET method.
    class Endpoint
      PATH_PARAMETER_REGEX = /\{(\w+)\}/

      attribute_setter_getter :name
      attribute_setter_getter :description
      attr_reader :outputs
      attr_reader :path_parameters
      attr_reader :query_parameters

      def initialize(name)
        @name = name
        @method = nil
        @path = nil
        @path_parameters = Apigen::ObjectType.new
        @query_parameters = Apigen::ObjectType.new
        @input = nil
        @outputs = []
        @description = nil
      end

      #
      # Declares the HTTP method.
      def method(method = nil)
        return @method unless method
        case method
        when :get, :post, :put, :delete
          @method = method
        else
          raise "Unknown HTTP method :#{method}."
        end
      end

      #
      # Declares the endpoint path relative to the host.
      def path(path = nil, &block)
        return @path unless path
        @path = path
        if PATH_PARAMETER_REGEX.match path
          set_path_parameters(path, &block)
        elsif block_given?
          raise 'A path block was provided but no URL parameter was found.'
        end
      end

      #
      # Declares query parameters.
      def query(&block)
        raise 'You must pass a block when calling `query`.' unless block_given?
        @query_parameters.instance_eval(&block)
      end

      ##
      # Declares the input type of an endpoint.
      def input(&block)
        return @input unless block_given?
        @input = Input.new
        @input.instance_eval(&block)
      end

      ##
      # Declares the output of an endpoint for a given status code.
      def output(name, &block)
        raise "Endpoint :#{@name} declares the output :#{name} twice." if @outputs.find { |o| o.name == name }
        output = Output.new name
        @outputs << output
        raise 'You must pass a block when calling `output`.' unless block_given?
        output.instance_eval(&block)
        output
      end

      ##
      # Updates an already-declared output.
      def update_output(name, &block)
        output = @outputs.find { |o| o.name == name }
        raise "Endpoint :#{@name} never declares the output :#{name} so it cannot be updated." unless output
        raise 'You must pass a block when calling `update_output`.' unless block_given?
        output.instance_eval(&block)
        output
      end

      def validate(model_registry)
        validate_properties
        validate_input(model_registry)
        validate_path_parameters(model_registry)
        validate_outputs(model_registry)
      end

      def to_s
        repr = "#{@name}: #{@input}"
        @outputs.each do |output|
          repr += "\n-> #{output}"
        end
        repr
      end

      private

      def set_path_parameters(path, &block)
        block = {} unless block_given?
        @path_parameters.instance_eval(&block)
        parameters_found_in_path = path.scan(PATH_PARAMETER_REGEX).map { |parameter, _| parameter.to_sym }
        ensure_parameters_found_in_path_all_defined(parameters_found_in_path)
        ensure_defined_parameters_all_appear_in_path(parameters_found_in_path)
      end

      def ensure_parameters_found_in_path_all_defined(parameters_found_in_path)
        parameters_found_in_path.each do |parameter|
          raise "Path parameter :#{parameter} in path #{@path} is not defined." unless @path_parameters.properties.key? parameter
        end
      end

      def ensure_defined_parameters_all_appear_in_path(parameters_found_in_path)
        @path_parameters.properties.each do |parameter, _type|
          raise "Parameter :#{parameter} does not appear in path #{@path}." unless parameters_found_in_path.include? parameter
        end
      end

      def validate_properties
        raise 'One of the endpoints is missing a name.' unless @name
        raise "Use `method :get/post/put/delete` to set an HTTP method for :#{@name}." unless @method
        raise "Use `path \"/some/path\"` to assign a path to :#{@name}." unless @path
      end

      def validate_input(model_registry)
        case @method
        when :put, :post
          raise "Use `input { type :typename }` to assign an input type to :#{@name}." unless @input
          @input.validate(model_registry)
        when :get
          raise "Endpoint :#{@name} with method GET cannot accept an input payload." if @input
        when :delete
          raise "Endpoint :#{@name} with method DELETE cannot accept an input payload." if @input
        end
      end

      def validate_path_parameters(model_registry)
        @path_parameters.validate model_registry
      end

      def validate_outputs(model_registry)
        raise "Endpoint :#{@name} does not declare any outputs" if @outputs.empty?
        @outputs.each do |output|
          output.validate model_registry
        end
      end
    end
  end
end
