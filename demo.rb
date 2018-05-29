require './apigen/rest'

api = Apigen::Rest::api do
  endpoint do
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
end

puts api
