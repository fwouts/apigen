# Swagger, OpenAPI and JSON Schema definition generator

[![CircleCI](https://circleci.com/gh/zenclabs/apigen.svg?style=svg)](https://circleci.com/gh/zenclabs/apigen)
[![Maintainability](https://api.codeclimate.com/v1/badges/ea4061181ad11a271bcb/maintainability)](https://codeclimate.com/github/zenclabs/apigen/maintainability)
[![Test Coverage](https://api.codeclimate.com/v1/badges/ea4061181ad11a271bcb/test_coverage)](https://codeclimate.com/github/zenclabs/apigen/test_coverage)
[![Ruby Gem](https://img.shields.io/gem/v/apigen.svg)](https://rubygems.org/gems/apigen)

`apigen` is a Ruby gem you can use to generate a valid OpenAPI or JSON Schema spec in Ruby. Your client/server code does not need to be written in Ruby.

Read the project overview: https://medium.com/@fwouts/project-openapi-definition-generator-dc440f4d6316

## Example

For a full-fledged example, see [example.rb](https://github.com/zenclabs/apigen/blob/master/spec/apigen/formats/example.rb) and corresponding tests:
- [Swagger (OpenAPI 2)](https://github.com/zenclabs/apigen/blob/master/spec/apigen/formats/swagger_spec.rb)
- [OpenAPI 3](https://github.com/zenclabs/apigen/blob/master/spec/apigen/formats/openapi_spec.rb)
- [JSON Schema](https://github.com/zenclabs/apigen/blob/master/spec/apigen/formats/jsonschema_spec.rb)

```ruby
require 'apigen/rest'

# Start an API declaration.
api = Apigen::Rest::Api.new
api.description 'Making APIs great again'

api.endpoint :list_users do
  description 'Returns a list of users'
  method :get
  path '/users'
  query do
    include_admin(:bool).explain do
      description 'Whether to include administrators or not'
      example false
    end
    order(:string?).explain do
      description 'A sorting order'
      example 'name ASC'
    end
  end
  output :success do
    description 'Success'
    status 200
    type :array do
      type :oneof do
        discriminator :type
        map(
          user: 'User',
          admin: 'Admin'
        )
      end
    end
  end
end

api.endpoint :create_user do
  description 'Creates a user'
  method :post
  path '/users'
  input do
    example(
      'name' => 'John',
      'email' => 'johnny@apple.com',
      'password' => 'foobar123'
    )
    type :object do
      name(:string).explain do
        description 'The name of the user'
        example 'John'
      end
      email(:string).explain do
        description "The user's email address"
      end
      password(:string).explain do
        description 'A password in plain text'
        example 'foobar123'
      end
      captcha :string
    end
  end
  output :success do
    status 200
    description 'Success'
    type :user
  end
  output :failure do
    status 401
    description 'Unauthorised failure'
    type :string
  end
end

api.endpoint :update_user do
  method :put
  path '/users/{id}' do
    id :string
  end
  input do
    description "Updates a user's properties. A subset of properties can be provided."
    example(
      'name' => 'Frank',
      'captcha' => 'AB123'
    )
    type :object do
      name :string?
      email :string?
      password :string?
      captcha :string
    end
  end
  output :success do
    status 200
    type :user
  end
  output :failure do
    status 401
    type :string
  end
end

api.endpoint :delete_user do
  method :delete
  path '/users/{id}' do
    id :string
  end
  output :success do
    status 200
    type :void
  end
  output :failure do
    status 401
    type :string
  end
end

api.model :person do
  type :oneof do
    discriminator :type
    map(
      user: 'User',
      admin: 'Admin'
    )
  end
end

api.model :user do
  description 'A user'
  example(
    'id' => 123,
    'profile' => {
      'name' => 'Frank',
      'avatar_url' => 'https://google.com/avatar.png'
    }
  )
  type :object do
    id :int32
    profile :user_profile
    has_super_powers :enum do
      value 'yes'
      value 'no'
    end
  end
end

api.model :user_profile do
  type :object do
    name :string
    avatar_url :string
  end
end

api.model :admin do
  description 'An admin'
  type :object do
    name :string
  end
end

# Ensure that the API spec is valid.
api.validate

# Output Swagger (OpenAPI 2).
require 'apigen/formats/swagger'
puts Apigen::Formats::Swagger::V2.generate api

# Output OpenAPI 3.
require 'apigen/formats/openapi'
puts Apigen::Formats::OpenAPI::V3.generate api

# Output JSON schema.
require 'apigen/formats/jsonschema'
puts Apigen::Formats::JsonSchema::Draft7.generate api
```
