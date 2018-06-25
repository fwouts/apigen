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
              }
            },
            "required": [
              "id",
              "profile"
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
          },
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
          }
        }
      }
    JSON
  end
end
