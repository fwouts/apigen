require 'apigen/rest'
require 'apigen/formats/swagger'
require 'apigen/formats/openapi'
require 'apigen/formats/jsonschema'

# Start an API declaration.
api = Apigen::Rest::Api.new

api.endpoint :list_users do
  method :get
  path "/users"
  output :success do
    status 200
    type :array do
      type :user
    end
  end
end

api.endpoint :create_user do
  method :post
  path "/users"
  input :object do
    name :string
    email :string
    password :string
    captcha :string
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

api.endpoint :update_user do
  method :put
  path "/users/{id}" do
    id :string
  end
  input :object do
    name :string?
    email :string?
    password :string?
    captcha :string
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
  path "/users/{id}" do
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

api.model :user do
  type :object do
    id :int32
    profile :user_profile
  end
end

api.model :user_profile do
  type :object do
    name :string
    avatar_url :string
  end
end

# Ensure that the API spec is valid.
api.validate

# Output Swagger (OpenAPI 2).
# puts Apigen::Formats::Swagger::V2.generate api

# Output OpenAPI 3.
# puts Apigen::Formats::OpenAPI::V3.generate api

# Output JSON schema.
# puts Apigen::Formats::JsonSchema::Draft7.generate api
