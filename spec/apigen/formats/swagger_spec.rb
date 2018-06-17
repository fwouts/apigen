require 'apigen/formats/swagger'
require 'apigen/formats/example'
require 'yaml'

describe Apigen::Formats::Swagger::V2 do
  it "generates expected output" do
    generated = YAML.load(Apigen::Formats::Swagger::V2.generate Apigen::example)
    expect(generated).to eq(YAML.load <<~YAML
---
swagger: '2.0'
info:
  version: 1.0.0
  title: API
  description: ''
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
      description: ''
      parameters: []
      responses:
        '200':
          description: ''
          schema:
            type: array
            items:
              "$ref": "#/definitions/user"
    post:
      description: ''
      parameters:
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
          - name
          - email
          - password
          - captcha
      responses:
        '200':
          description: ''
          schema:
            "$ref": "#/definitions/user"
        '401':
          description: ''
          schema:
            type: string
  "/users/{id}":
    put:
      description: ''
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
      responses:
        '200':
          description: ''
          schema:
            "$ref": "#/definitions/user"
        '401':
          description: ''
          schema:
            type: string
    delete:
      description: ''
      parameters:
      - in: path
        name: id
        required: true
        type: string
      responses:
        '200':
          description: ''
        '401':
          description: ''
          schema:
            type: string
definitions:
  user:
    type: object
    properties:
      id:
        type: integer
        format: int32
      profile:
        "$ref": "#/definitions/user_profile"
    required:
    - id
    - profile
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
    )
  end
end
