# frozen_string_literal: true

require './lib/apigen/model'
require './lib/apigen/util'

PATH_PARAMETER_REGEX = /\{(\w+)\}/

module Apigen
  ##
  # Rest contains what you need to declare a REST-ish API.
  module Rest
    ##
    # Declares an API.
    def self.api(&block)
      api = Api.new
      api.instance_eval(&block)
      api.validate
      api
    end

    ##
    # Api is a self-contained definition of a REST API, includings its endpoints and data types.
    class Api
      attr_reader :endpoints

      def initialize
        @endpoints = []
        @model_registry = Apigen::ModelRegistry.new
      end

      ##
      # Declares a specific endpoint.
      def endpoint(name, &block)
        endpoint = Endpoint.new name
        @endpoints << endpoint
        endpoint.instance_eval(&block)
      end

      ##
      # Declares a data model.
      def model(name, &block)
        @model_registry.model name, &block
      end

      def models
        @model_registry.models
      end

      def validate
        @model_registry.validate
        @endpoints.each do |e|
          e.validate @model_registry
        end
      end

      def to_s
        repr = "Endpoints:\n\n"
        repr += @endpoints.map(&:to_s).join "\n"
        repr += "\n\nTypes:\n\n"
        repr += @model_registry.to_s
        repr
      end
    end

    ##
    # Endpoint is a definition of a specific endpoint in the API, e.g. /users with GET method.
    class Endpoint
      attribute_setter_getter :name
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
        raise 'A block must be passed to define query fields.' unless block_given?
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
        output = Output.new name
        @outputs << output
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
        expected_parameters = path.scan(PATH_PARAMETER_REGEX).map { |parameter, _| parameter.to_sym }
        ensure_parameters_all_defined(expected_parameters)
      end

      def ensure_parameters_all_defined(expected_parameters)
        expected_parameters.each do |parameter|
          raise "Path parameter :#{parameter} in path #{@path} is not defined." unless @path_parameters.properties.key? parameter
        end
        @path_parameters.properties.each do |parameter, _type|
          raise "Parameter :#{parameter} does not appear in path #{@path}." unless expected_parameters.include? parameter
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

    ##
    # Input is the request body expected by an API endpoint.
    class Input
      def initialize
        @type = nil
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

    ##
    # Output is the response type associated with a specific status code for an API endpoint.
    class Output
      attribute_setter_getter :status

      def initialize(name)
        @name = name
        @status = nil
        @type = nil
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
        raise 'One of the outputs is missing a name.' unless @name
        raise "Use `status [code]` to assign a status code to :#{@name}." unless @status
        raise "Use `type :typename` to assign a type to :#{@name}." unless @type
      end
    end
  end
end
