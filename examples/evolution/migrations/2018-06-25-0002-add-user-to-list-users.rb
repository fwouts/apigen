# frozen_string_literal: true

##
# Adds a User model and returns it from /users.
class AddUserToListUsers < Apigen::Migration
  def up
    update_endpoint :list_users do
      update_output :success do
        type :user
      end
    end

    add_model :user do
      type :object do
        name :string
      end
    end
  end
end
