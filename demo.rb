require './apigen/rest'

api = Apigen::Rest::Api.new

api.endpoint do
  name :get_user
  path "/users/:id"
  input :void
  output do
    is :success
    status 200
    type :user
  end
  output do
    is :failure
    status 401
    type :string
  end
end

api.model do
  name :user
  type :struct do
    name :string
    age :optional do
      type :int32
    end
    children :list do
      item :struct do
        name :string
      end
    end
    additional_info :optional do
      type :struct do
        first_name :string
        last_name :string
      end
    end
  end
end

api.model do
  name :user_list
  type :list do
    item :user
  end
end

api.validate

puts api
