require './lib/apigen/model'
require './lib/apigen/util'

module Apigen
  module Rest

    ##
    # Declares an API.
    #
    # Example usage:
    #  api = Apigen::Rest::Api do
    #    endpoint do
    #      name :get_user
    #      path "/users/:id"
    #      input :void
    #      output :success do
    #        status 200
    #        type :user
    #      end
    #      output :failure do
    #        status 401
    #        type :string
    #      end
    #    end
    #  end
    def self.api(&block)
      api = Api.new
      api.instance_eval &block
      api.validate
      api
    end
    
    class Api
      def initialize
        @endpoints = []
        @model_registry = Apigen::ModelRegistry.new
      end

      ##
      # Declares a specific endpoint.
      def endpoint(&block)
        endpoint = Endpoint.new
        @endpoints << endpoint
        endpoint.instance_eval &block
      end

      ##
      # Declares a data model.
      def model(&block)
        @model_registry.model &block
      end

      def validate
        for e in @endpoints do
          e.validate
        end
        @model_registry.validate
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
      attribute_setter :name
      attribute_setter :path
      attribute_setter :input

      def initialize
        @name = nil
        @path = nil
        @input = nil
        @outputs = []
      end

      ##
      # Declares the output of an endpoint for a given status code.
      def output(name, &block)
        output = Output.new name
        @outputs << output
        output.instance_eval &block
        output
      end

      def validate
        raise "Use `name :endpoint_name` to declare each endpoint." unless @name
        raise "Use `path \"/some/path\"` to assign a path to :#{@name}." unless @path
        raise "Use `input :typename` to assign an input type to :#{@name}." unless @input
        raise "Endpoint :#{@name} does not declare any outputs" unless @outputs.length > 0
        for output in @outputs
          output.validate
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
      attribute_setter :status
      attribute_setter :type

      def initialize(name)
        @name = name
        @status = nil
        @type = nil
      end

      def validate
        raise "One of the outputs is missing a name." unless @name
        raise "Use `status [code]` to assign a status code to :#{@is}." unless @status
        raise "Use `type :typename` to assign a type to :#{@is}." unless @type
      end

      def to_s
        "#{@name} #{@status} #{@type}"
      end
    end
  end
end
