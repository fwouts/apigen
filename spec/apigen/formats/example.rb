# frozen_string_literal: true

require 'apigen/rest'

module Apigen
  ##
  # Generates an example API with a variety of endpoints and types.
  def self.example
    api = Apigen::Rest::Api.new

    api.endpoint :list_users do
      method :get
      path '/users'
      output :success do
        status 200
        type :array do
          type :user
        end
      end
    end

    api.endpoint :create_user do
      method :post
      path '/users'
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
      path '/users/{id}' do
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

    api
  end
end
