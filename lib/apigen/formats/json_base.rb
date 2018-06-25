# frozen_string_literal: true

module Apigen
  module Formats
    ##
    # JsonBase contains the common logic for API declaration formats based on JSON Schema,
    # such as JSON Schema itself, Swagger and OpenAPI.
    module JsonBase
      private

      def definitions(api)
        hash = {}
        api.models.each do |key, model|
          hash[key.to_s] = schema(api, model.type, model.description, model.example)
        end
        hash
      end

      def schema(api, type, description = nil, example = nil)
        schema = schema_without_description(api, type)
        schema['description'] = description unless description.nil?
        schema['example'] = example unless example.nil?
        schema
      end

      def schema_without_description(api, type)
        case type
        when Apigen::ObjectType
          object_schema(api, type)
        when Apigen::ArrayType
          array_schema(api, type)
        when Apigen::OneofType
          oneof_schema(api, type)
        when Apigen::PrimaryType
          primary_schema(type)
        when Apigen::ReferenceType
          reference_schema(type)
        else
          raise "Unsupported type: #{type}."
        end
      end

      def object_schema(api, object_type)
        {
          'type' => 'object',
          'properties' => object_type.properties.map { |name, property| object_property(api, name, property) }.to_h,
          'required' => object_type.properties.select { |_name, property| property.required? }.map { |name, _property| name.to_s }
        }
      end

      def object_property(api, name, property)
        [name.to_s, schema(api, property.type, property.description, property.example)]
      end

      def array_schema(api, array_type)
        {
          'type' => 'array',
          'items' => schema(api, array_type.type)
        }
      end

      def oneof_schema(_api, oneof_type)
        schema = {
          'oneOf' => oneof_type.mapping.keys.map { |model_name| { '$ref' => model_ref(model_name) } }
        }
        if supports_discriminator? && oneof_type.discriminator
          schema['discriminator'] = {
            'propertyName' => oneof_type.discriminator.to_s,
            'mapping' => oneof_type.mapping.map { |model_name, disc_value| [disc_value, model_ref(model_name)] }.to_h
          }
        end
        schema
      end

      def primary_schema(primary_type)
        case primary_type.shape
        when :string
          {
            'type' => 'string'
          }
        when :int32
          {
            'type' => 'integer',
            'format' => 'int32'
          }
        when :bool
          {
            'type' => 'boolean'
          }
        else
          raise "Unsupported primary type :#{primary_type.shape}."
        end
      end

      def reference_schema(reference_type)
        { '$ref' => model_ref(reference_type.model_name) }
      end
    end
  end
end
