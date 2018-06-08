require './lib/apigen/model'
require './lib/apigen/util'

PATH_PARAMETER_REGEX = /\{(\w+)\}/

module Apigen
  module Rest

    ##
    # Declares an API.
    def self.api &block
      api = Api.new
      api.instance_eval &block
      api.validate
      api
    end

    class Api
      attr_reader :endpoints

      def initialize
        @endpoints = []
        @model_registry = Apigen::ModelRegistry.new
      end

      ##
      # Declares a specific endpoint.
      def endpoint name, &block
        endpoint = Endpoint.new name
        @endpoints << endpoint
        endpoint.instance_eval &block
      end

      ##
      # Declares a data model.
      def model name, &block
        @model_registry.model name, &block
      end

      def models
        @model_registry.models
      end

      def validate
        @model_registry.validate
        for e in @endpoints do
          e.validate @model_registry
        end
      end

      def to_s
        repr = "Endpoints:\n\n"
        repr += @endpoints.map{ |e| e.to_s }.join "\n"
        repr += "\n\nTypes:\n\n"
        repr += @model_registry.to_s
        repr
      end
    end

    class Endpoint
      attribute_setter_getter :name
      attr_reader :outputs
      attr_reader :path_parameters

      def initialize name
        @name = name
        @method = nil
        @path = nil
        @path_parameters = Apigen::Object.new
        @input = nil
        @outputs = []
      end

      #
      # Declares the HTTP method.
      def method method = nil
        return @method if not method
        case method
        when :get, :post, :put, :delete
          @method = method
        else
          raise "Unknown HTTP method :#{method}."
        end
      end

      #
      # Declares the endpoint path relative to the host.
      def path path = nil, &block
        return @path if not path
        @path = path
        if PATH_PARAMETER_REGEX.match path
          block = {} if not block_given?
          @path_parameters.instance_eval &block
          parameters_in_url = path.scan(PATH_PARAMETER_REGEX).map do |parameter_str,|
            parameter_str.to_sym
          end
          for parameter in parameters_in_url do
            raise "Path parameter :#{parameter} in path #{@path} is not defined." if not @path_parameters.properties.key? parameter
          end
          @path_parameters.properties.each do |parameter, type|
            raise "Parameter :#{parameter} does not appear in path #{@path}." if not parameters_in_url.include? parameter
          end
        else
          raise "A path block was provided but no URL parameter was found." if block
        end
      end

      ##
      # Declares the input type of an endpoint.
      def input type = nil, &block
        return @input if not type
        @input = Apigen::Model.type type, &block
      end

      ##
      # Declares the output of an endpoint for a given status code.
      def output name, &block
        output = Output.new name
        @outputs << output
        output.instance_eval &block
        output
      end

      def validate model_registry
        raise "One of the endpoints is missing a name." unless @name
        raise "Use `method :get/post/put/delete` to set an HTTP method for :#{@name}." unless @method
        raise "Use `path \"/some/path\"` to assign a path to :#{@name}." unless @path
        @path_parameters.validate model_registry
        case @method
        when :put, :post
          raise "Use `input :typename` to assign an input type to :#{@name}." unless @input
          model_registry.check_type @input
        when :get
          raise "Endpoint :#{@name} with method GET cannot accept an input payload." if @input
        when :delete
          raise "Endpoint :#{@name} with method DELETE cannot accept an input payload." if @input
        end
        raise "Endpoint :#{@name} does not declare any outputs" unless @outputs.length > 0
        for output in @outputs
          output.validate model_registry
        end
      end

      def to_s
        repr = "#{@name}: #{@input}"
        for output in @outputs do
          repr += "\n-> #{output}"
        end
        repr
      end
    end

    class Output
      attribute_setter_getter :status

      def initialize name
        @name = name
        @status = nil
        @type = nil
      end

      ##
      # Declares the output type.
      def type type = nil, &block
        return @type if not type
        @type = Apigen::Model.type type, &block
      end

      def validate model_registry
        raise "One of the outputs is missing a name." unless @name
        raise "Use `status [code]` to assign a status code to :#{@name}." unless @status
        raise "Use `type :typename` to assign a type to :#{@name}." unless @type
        model_registry.check_type @type
      end

      def to_s
        "#{@name} #{@status} #{@type}"
      end
    end
  end
end
