require 'apigen/formats/openapi'
require 'apigen/formats/example'
require 'yaml'

describe Apigen::Formats::OpenAPI::V3 do
  it "generates expected output" do
    generated = YAML.load(Apigen::Formats::OpenAPI::V3.generate Apigen::example)
    expect(generated).to eq(YAML.load <<~YAML
---
openapi: 3.0.0
info:
  version: 1.0.0
  title: API
  description: ''
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
      description: ''
      parameters: []
      responses:
        '200':
          description: ''
          content:
            application/json:
              schema:
                type: array
                items:
                  "$ref": "#/components/schemas/user"
    post:
      operationId: create_user
      description: ''
      parameters: []
      responses:
        '200':
          description: ''
          content:
            application/json:
              schema:
                "$ref": "#/components/schemas/user"
        '401':
          description: ''
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
              - name
              - email
              - password
              - captcha
  "/users/{id}":
    put:
      operationId: update_user
      description: ''
      parameters:
      - in: path
        name: id
        required: true
        schema:
          type: string
      responses:
        '200':
          description: ''
          content:
            application/json:
              schema:
                "$ref": "#/components/schemas/user"
        '401':
          description: ''
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
    delete:
      operationId: delete_user
      description: ''
      parameters:
      - in: path
        name: id
        required: true
        schema:
          type: string
      responses:
        '200':
          description: ''
        '401':
          description: ''
          content:
            application/json:
              schema:
                type: string
components:
  schemas:
    user:
      type: object
      properties:
        id:
          type: integer
          format: int32
        profile:
          "$ref": "#/components/schemas/user_profile"
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
