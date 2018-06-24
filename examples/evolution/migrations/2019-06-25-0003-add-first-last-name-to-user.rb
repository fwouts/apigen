# frozen_string_literal: true

##
# Removes User.name, replacing it with first_name and last_name.
class AddFirstLastNameToUser < Apigen::Migration
  def up
    update_model :user do
      update_object_properties do
        remove :name
        add do
          first_name :string
          last_name :string
        end
      end
    end
  end
end
