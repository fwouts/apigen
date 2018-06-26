# frozen_string_literal: true

require 'apigen/formats/swagger'
require 'apigen/formats/example'
require 'yaml'

describe Apigen::Formats::Swagger::V2 do
  it 'generates expected output' do
    generated = Apigen::Formats::Swagger::V2.generate(Apigen.example)
    expect(generated).to eq(<<~YAML)
      ---
      swagger: '2.0'
      info:
        version: 1.0.0
        title: API
        description: Making APIs great again
        termsOfService: ''
        contact:
          name: ''
        license:
          name: ''
      host: localhost
      basePath: "/"
      schemes:
      - http
      - https
      consumes:
      - application/json
      produces:
      - application/json
      paths:
        "/users":
          get:
            parameters:
            - in: query
              name: include_admin
              required: true
              type: boolean
              description: Whether to include administrators or not
              example: false
            - in: query
              name: order
              required: false
              type: string
              description: A sorting order
              example: name ASC
            responses:
              '200':
                description: Success
                schema:
                  type: object
                  properties:
                    list:
                      type: array
                      items:
                        oneOf:
                        - "$ref": "#/definitions/user"
                        - "$ref": "#/definitions/admin"
                        discriminator:
                          propertyName: type
                          mapping:
                            User: "#/definitions/user"
                            Admin: "#/definitions/admin"
                    next:
                      type: string
                  required:
                  - list
            description: Returns a list of users
          post:
            parameters:
            - name: input
              in: body
              required: true
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
            responses:
              '200':
                description: Success
                schema:
                  "$ref": "#/definitions/user"
              '401':
                description: Unauthorised failure
                schema:
                  type: string
            description: Creates a user
        "/users/{id}":
          put:
            parameters:
            - in: path
              name: id
              required: true
              type: string
            - name: input
              in: body
              required: true
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
            responses:
              '200':
                schema:
                  "$ref": "#/definitions/user"
              '401':
                schema:
                  type: string
          delete:
            parameters:
            - in: path
              name: id
              required: true
              type: string
            responses:
              '200': {}
              '401':
                schema:
                  type: string
      definitions:
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
          - "$ref": "#/definitions/user"
          - "$ref": "#/definitions/admin"
          discriminator:
            propertyName: type
            mapping:
              User: "#/definitions/user"
              Admin: "#/definitions/admin"
        user:
          type: object
          properties:
            id:
              type: integer
              format: int32
            profile:
              "$ref": "#/definitions/user_profile"
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
    expect { Apigen::Formats::Swagger::V2.generate(api) }.to raise_error 'Unsupported primary type :void.'
  end

  it 'fails with unknown type' do
    api = Apigen::Rest::Api.new
    api.model :user do
      type :object do
        name :string
      end
    end
    api.models[:user].type.properties[:name] = Apigen::ObjectProperty.new('not a type')
    expect { Apigen::Formats::Swagger::V2.generate(api) }.to raise_error 'Unsupported type: not a type.'
  end
end
