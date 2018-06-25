# frozen_string_literal: true

require 'apigen/models/registry'

RSpec.describe Apigen::ModelRegistry do
  describe '#model' do
    it 'allows declaring simple models' do
      registry = Apigen::ModelRegistry.new
      registry.model :name do
        type :string
      end
      expect(registry.models.keys).to eq [:name]
      expect(registry.models[:name].type).to eq Apigen::PrimaryType.new(:string)
    end

    it 'allows declaring complex models' do
      registry = Apigen::ModelRegistry.new
      registry.model :user do
        type :object do
          name :string
        end
      end
      expect(registry.models.keys).to eq [:user]
      expect(registry.models[:user].type).to be_a Apigen::ObjectType
    end

    it 'fails when creating a model without a block' do
      registry = Apigen::ModelRegistry.new
      expect do
        registry.model :user
      end.to raise_error 'You must pass a block when calling `model`.'
    end
  end

  describe '#validate' do
    it 'validates primary types (valid)' do
      registry = Apigen::ModelRegistry.new
      registry.model :name do
        type :string
      end
      registry.model :date do
        type :int32
      end
      registry.model :truth do
        type :bool
      end
      registry.model :nothing do
        type :void
      end
      registry.validate
    end

    it 'validates primary types (invalid)' do
      registry = Apigen::ModelRegistry.new
      registry.model :name do
        type :missing
      end
      expect do
        registry.validate
      end.to raise_error 'Model :missing is not defined.'
    end

    it 'validates object models (valid)' do
      registry = Apigen::ModelRegistry.new
      registry.model :user do
        type :object do
          name :name
        end
      end
      registry.model :name do
        type :string
      end
      registry.validate
    end

    it 'validates object models (invalid)' do
      registry = Apigen::ModelRegistry.new
      registry.model :user do
        type :object do
          name :missing
        end
      end
      expect do
        registry.validate
      end.to raise_error 'Model :missing is not defined.'
    end

    it 'validates array models (valid)' do
      registry = Apigen::ModelRegistry.new
      registry.model :name_list do
        type :array do
          type :name
        end
      end
      registry.model :name do
        type :string
      end
      registry.validate
    end

    it 'validates array models (invalid)' do
      registry = Apigen::ModelRegistry.new
      registry.model :name_list do
        type :array do
          type :missing
        end
      end
      expect do
        registry.validate
      end.to raise_error 'Model :missing is not defined.'
    end
  end

  describe '#to_s' do
    it 'generates a reasonable output' do
      registry = Apigen::ModelRegistry.new
      registry.model :name_list do
        type :array do
          type :name
        end
      end
      registry.model :name do
        type :string
      end
      expect(registry.to_s).to eq "name_list: ArrayType<name>\nname: string"
    end
  end
end
