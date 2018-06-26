# frozen_string_literal: true

require 'apigen/formats/openapi'
require 'apigen/formats/example'
require 'yaml'

describe Apigen::Formats::OpenAPI::V3 do
  it 'generates expected output' do
    generated = Apigen::Formats::OpenAPI::V3.generate(Apigen.example)
    expect(generated).to eq(<<~YAML)
      ---
      openapi: 3.0.0
      info:
        version: 1.0.0
        title: API
        description: Making APIs great again
        termsOfService: ''
        contact:
          name: ''
        license:
          name: ''
      servers:
      - url: http://localhost
      paths:
        "/users":
          get:
            operationId: list_users
            parameters:
            - in: query
              name: include_admin
              required: true
              schema:
                type: boolean
              description: Whether to include administrators or not
              example: false
            - in: query
              name: order
              required: false
              schema:
                type: string
              description: A sorting order
              example: name ASC
            responses:
              '200':
                description: Success
                content:
                  application/json:
                    schema:
                      type: object
                      properties:
                        list:
                          type: array
                          items:
                            oneOf:
                            - "$ref": "#/components/schemas/user"
                            - "$ref": "#/components/schemas/admin"
                            discriminator:
                              propertyName: type
                              mapping:
                                User: "#/components/schemas/user"
                                Admin: "#/components/schemas/admin"
                        next:
                          type: string
                      required:
                      - list
            description: Returns a list of users
          post:
            operationId: create_user
            parameters: []
            responses:
              '200':
                description: Success
                content:
                  application/json:
                    schema:
                      "$ref": "#/components/schemas/user"
              '401':
                description: Unauthorised failure
                content:
                  application/json:
                    schema:
                      type: string
            description: Creates a user
            requestBody:
              required: true
              content:
                application/json:
                  schema:
                    type: object
                    properties:
                      name:
                        type: string
                        description: The name of the user
                        example: John
                      email:
                        type: string
                        description: The user's email address
                      password:
                        type: string
                        description: A password in plain text
                        example: foobar123
                      captcha:
                        type: string
                    required:
                    - name
                    - email
                    - password
                    - captcha
              example:
                name: John
                email: johnny@apple.com
                password: foobar123
        "/users/{id}":
          put:
            operationId: update_user
            parameters:
            - in: path
              name: id
              required: true
              schema:
                type: string
            responses:
              '200':
                content:
                  application/json:
                    schema:
                      "$ref": "#/components/schemas/user"
              '401':
                content:
                  application/json:
                    schema:
                      type: string
            requestBody:
              required: true
              content:
                application/json:
                  schema:
                    type: object
                    properties:
                      name:
                        type: string
                      email:
                        type: string
                      password:
                        type: string
                      captcha:
                        type: string
                    required:
                    - captcha
              description: Updates a user's properties. A subset of properties can be provided.
              example:
                name: Frank
                captcha: AB123
          delete:
            operationId: delete_user
            parameters:
            - in: path
              name: id
              required: true
              schema:
                type: string
            responses:
              '200': {}
              '401':
                content:
                  application/json:
                    schema:
                      type: string
      components:
        schemas:
          admin:
            type: object
            properties:
              name:
                type: string
            required:
            - name
            description: An admin
          person:
            oneOf:
            - "$ref": "#/components/schemas/user"
            - "$ref": "#/components/schemas/admin"
            discriminator:
              propertyName: type
              mapping:
                User: "#/components/schemas/user"
                Admin: "#/components/schemas/admin"
          user:
            type: object
            properties:
              id:
                type: integer
                format: int32
              profile:
                "$ref": "#/components/schemas/user_profile"
              has_super_powers:
                type: string
                enum:
                - 'yes'
                - 'no'
            required:
            - id
            - profile
            - has_super_powers
            description: A user
            example:
              id: 123
              profile:
                name: Frank
                avatar_url: https://google.com/avatar.png
          user_profile:
            type: object
            properties:
              name:
                type: string
              avatar_url:
                type: string
            required:
            - name
            - avatar_url
    YAML
  end

  it 'fails with void type' do
    api = Apigen::Rest::Api.new
    api.model :user do
      type :object do
        name :void
      end
    end
    expect { Apigen::Formats::OpenAPI::V3.generate(api) }.to raise_error 'Unsupported primary type :void.'
  end

  it 'fails with unknown type' do
    api = Apigen::Rest::Api.new
    api.model :user do
      type :object do
        name :string
      end
    end
    api.models[:user].type.properties[:name] = Apigen::ObjectProperty.new('not a type')
    expect { Apigen::Formats::OpenAPI::V3.generate(api) }.to raise_error 'Unsupported type: not a type.'
  end
end
