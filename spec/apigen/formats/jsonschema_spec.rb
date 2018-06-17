# frozen_string_literal: true

require 'apigen/formats/jsonschema'
require 'apigen/formats/example'
require 'json'

describe Apigen::Formats::JsonSchema::Draft7 do
  it 'generates expected output' do
    generated = JSON.parse(Apigen::Formats::JsonSchema::Draft7.generate(Apigen.example))
    expect(generated).to eq(JSON.parse(<<~JSON)
      {
        "$schema": "http://json-schema.org/draft-07/schema#",
        "definitions": {
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
            ]
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
                           )
  end
end
