# frozen_string_literal: true

require 'apigen/formats/jsonschema'
require 'apigen/formats/example'
require 'json'

describe Apigen::Formats::JsonSchema::Draft7 do
  it 'generates expected output' do
    generated = Apigen::Formats::JsonSchema::Draft7.generate(Apigen.example).strip
    expect(generated).to eq(<<~JSON.strip)
      {
        "$schema": "http://json-schema.org/draft-07/schema#",
        "definitions": {
          "admin": {
            "type": "object",
            "properties": {
              "name": {
                "type": "string"
              }
            },
            "required": [
              "name"
            ],
            "description": "An admin"
          },
          "person": {
            "oneOf": [
              {
                "$ref": "#/definitions/user"
              },
              {
                "$ref": "#/definitions/admin"
              }
            ]
          },
          "user": {
            "type": "object",
            "properties": {
              "id": {
                "type": "integer",
                "format": "int32"
              },
              "profile": {
                "$ref": "#/definitions/user_profile"
              },
              "has_super_powers": {
                "type": "string",
                "enum": [
                  "yes",
                  "no"
                ]
              }
            },
            "required": [
              "id",
              "profile",
              "has_super_powers"
            ],
            "description": "A user",
            "example": {
              "id": 123,
              "profile": {
                "name": "Frank",
                "avatar_url": "https://google.com/avatar.png"
              }
            }
          },
          "user_profile": {
            "type": "object",
            "properties": {
              "name": {
                "type": "string"
              },
              "avatar_url": {
                "type": "string"
              }
            },
            "required": [
              "name",
              "avatar_url"
            ]
          }
        }
      }
    JSON
  end

  it 'fails with void type' do
    api = Apigen::Rest::Api.new
    api.model :user do
      type :object do
        name :void
      end
    end
    expect { Apigen::Formats::JsonSchema::Draft7.generate(api) }.to raise_error 'Unsupported primary type :void.'
  end

  it 'fails with unknown type' do
    api = Apigen::Rest::Api.new
    api.model :user do
      type :object do
        name :string
      end
    end
    api.models[:user].type.properties[:name] = Apigen::ObjectProperty.new('not a type')
    expect { Apigen::Formats::JsonSchema::Draft7.generate(api) }.to raise_error 'Unsupported type: not a type.'
  end
end
