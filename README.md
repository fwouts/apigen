# OpenAPI spec generator for Ruby

`apigen` is a Ruby gem you can use to generate a valid OpenAPI spec in Ruby.

## Warning!
This is a brand new project and isn't yet functional. The syntax may change and
the gem doesn't yet generate an OpenAPI spec.

## Example

```ruby
require 'apigen/rest'

# Start an API declaration.
api = Apigen::Rest::Api.new

# Declare a REST endpoint /users/:id which takes no input
# and returns either a User or a failure.
api.endpoint :get_user do
  path "/users/:id"
  input :void
  output :success do
    status 200
    type :user
  end
  output :failure do
    status 401
    type :string
  end
end

# Declare what a User is.
api.model :user do
  # User is a struct (multiple fields).
  type :struct do
    # User.name is a mandatory string.
    name :string
    # User.age is an optional integer.
    age :int32?
    # Alternatively, use:
    # age :optional do
    #   type :int32
    # end
    # User.children is a list of users.
    children :list do
      item :user
    end
    # User.additional_info is an optional struct.
    additional_info :struct? do
      first_name :string
      last_name :string
    end
  end
end

# Ensure that the API spec is valid.
api.validate

# Show a summary of the API.
puts api
```
