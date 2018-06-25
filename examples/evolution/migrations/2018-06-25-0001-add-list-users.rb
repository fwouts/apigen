# frozen_string_literal: true

##
# Adds a /users endpoint to fetch list of users.
class AddListUsers < Apigen::Migration
  def up
    add_endpoint :list_users do
      method :get
      path '/users'
      output :success do
        description 'Success'
        status 200
        type :void
      end
    end
  end
end
