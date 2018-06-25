# frozen_string_literal: true

require 'apigen/migration'
require 'apigen/rest'

RSpec.describe Apigen::Migration do
  let(:api) { Apigen::Rest::Api.new }

  describe '#up' do
    it 'complains if #up is not defined' do
      class MissingUp < Apigen::Migration
      end

      expect { api.migrate(MissingUp) }.to raise_error 'Migration subclasses must implement #up.'
    end
  end

  describe '#add_endpoints' do
    it 'adds endpoint' do
      class AddEndpoint < Apigen::Migration
        def up
          add_endpoint :list_users do
            method :get
            path '/users'
            output :success do
              status 200
              type :void
            end
          end
        end
      end

      expect(api.endpoints.size).to eq(0)

      api.migrate(AddEndpoint)
      api.validate

      expect(api.endpoints.size).to eq(1)
      expect(api.endpoints[0].name).to eq(:list_users)
    end

    it 'refuses to override existing endpoint' do
      api.endpoint :list_users do
        method :get
        path '/users'
        output :success do
          status 201
          type :user
        end
      end

      class AddEndpoint < Apigen::Migration
        def up
          add_endpoint :list_users do
            method :get
            path '/users'
            output :success do
              status 200
              type :void
            end
          end
        end
      end

      expect { api.migrate(AddEndpoint) }.to raise_error 'Endpoint :list_users is declared twice.'
    end
  end

  describe '#update_endpoint' do
    it 'updates endpoint' do
      api.endpoint :list_users do
        method :get
        path '/users'
        output :success do
          status 201
          type :user
        end
      end

      class UpdateEndpoint < Apigen::Migration
        def up
          update_endpoint :list_users do
            update_output :success do
              status 200
              type :void
            end
          end
        end
      end

      expect(api.endpoints.size).to eq(1)
      expect(api.endpoints[0].name).to eq(:list_users)
      expect(api.endpoints[0].outputs.size).to eq(1)
      expect(api.endpoints[0].outputs[0].status).to eq(201)
      expect(api.endpoints[0].outputs[0].type).to eq(Apigen::ReferenceType.new(:user))

      api.migrate(UpdateEndpoint)
      api.validate

      expect(api.endpoints.size).to eq(1)
      expect(api.endpoints[0].name).to eq(:list_users)
      expect(api.endpoints[0].outputs.size).to eq(1)
      expect(api.endpoints[0].outputs[0].status).to eq(200)
      expect(api.endpoints[0].outputs[0].type).to eq(Apigen::PrimaryType.new(:void))
    end

    it 'refuses to override existing endpoint output' do
      api.endpoint :list_users do
        method :get
        path '/users'
        output :success do
          status 201
          type :user
        end
      end

      class UpdateEndpoint < Apigen::Migration
        def up
          update_endpoint :list_users do
            output :success do
              status 200
              type :void
            end
          end
        end
      end

      expect { api.migrate(UpdateEndpoint) }.to raise_error 'Endpoint :list_users declares the output :success twice.'
    end
  end

  describe '#remove_endpoint' do
    it 'removes endpoints' do
      api.endpoint :list_users do
        method :get
        path '/users'
        output :success do
          status 201
          type :user
        end
      end

      class RemoveEndpoint < Apigen::Migration
        def up
          remove_endpoint :list_users
        end
      end

      expect(api.endpoints.size).to eq(1)

      api.migrate(RemoveEndpoint)
      api.validate

      expect(api.endpoints.size).to eq(0)
    end

    it 'refuses to remove nonexistent endpoints' do
      class RemoveEndpoint < Apigen::Migration
        def up
          remove_endpoint :list_users
        end
      end

      expect { api.migrate(RemoveEndpoint) }.to raise_error 'No such endpoint :list_users.'
    end
  end

  describe '#add_model' do
    it 'adds models' do
      class AddModel < Apigen::Migration
        def up
          add_model :user do
            type :object do
              name :string
            end
          end
        end
      end

      api.migrate(AddModel)
      api.validate

      expect(api.models.size).to eq(1)
      expect(api.models[:user].type).to be_a(Apigen::ObjectType)
    end

    it 'refuses to add existing model' do
      api.model :user do
        type :string
      end

      class AddModel < Apigen::Migration
        def up
          add_model :user do
            type :object do
              name :string
            end
          end
        end
      end

      expect { api.migrate(AddModel) }.to raise_error 'Model :user is declared twice.'
    end
  end

  describe '#update_model' do
    it 'updates models' do
      api.model :user do
        type :object do
          name :string
          birthdate :string
        end
      end

      class UpdateModel < Apigen::Migration
        def up
          update_model :user do
            update_object_properties do
              add do
                first_name :string
                last_name :string
              end

              remove :name
            end
          end
        end
      end

      expect(api.models[:user].type.properties.keys).to eq(%i[name birthdate])

      api.migrate(UpdateModel)
      api.validate

      expect(api.models[:user].type.properties.keys).to eq(%i[birthdate first_name last_name])
    end

    it 'refuses to update nonexistent models' do
      class UpdateModel < Apigen::Migration
        def up
          update_model :user do
            update_object_properties do
              add do
                first_name :string
                last_name :string
              end

              remove :name
            end
          end
        end
      end

      expect { api.migrate(UpdateModel) }.to raise_error 'No such model :user.'
    end

    it 'refuses to add existing properties' do
      api.model :user do
        type :object do
          name :string
          birthdate :string
        end
      end

      class UpdateModel < Apigen::Migration
        def up
          update_model :user do
            update_object_properties do
              add do
                name :string
              end
            end
          end
        end
      end

      expect { api.migrate(UpdateModel) }.to raise_error 'Property :name is defined multiple times.'
    end

    it 'refuses to remove nonexistent properties' do
      api.model :user do
        type :object do
          name :string
          birthdate :string
        end
      end

      class UpdateModel < Apigen::Migration
        def up
          update_model :user do
            update_object_properties do
              remove :first_name
            end
          end
        end
      end

      expect { api.migrate(UpdateModel) }.to raise_error 'Cannot remove nonexistent property :first_name.'
    end
  end

  describe '#remove_model' do
    it 'removes models' do
      api.model :user do
        type :object do
          name :string
          birthdate :string
        end
      end

      class RemoveModel < Apigen::Migration
        def up
          remove_model :user
        end
      end

      expect(api.models.size).to eq(1)

      api.migrate(RemoveModel)
      api.validate

      expect(api.models).to eq({})
    end

    it 'refuses to remove nonexistent models' do
      class RemoveModel < Apigen::Migration
        def up
          remove_model :user
        end
      end

      expect { api.migrate(RemoveModel) }.to raise_error 'No such model :user.'
    end
  end
end
