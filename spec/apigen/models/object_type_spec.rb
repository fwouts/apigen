# frozen_string_literal: true

require 'apigen/models/object_type'

RSpec.describe Apigen::ObjectType do
  it 'responds to any method' do
    type = Apigen::ObjectType.new
    expect(type.respond_to?(:property1)).to be true
    expect(type.respond_to?(:property2)).to be true
    expect(type.respond_to?(:property3)).to be true
  end

  it 'adds properties by default' do
    type = Apigen::ObjectType.new
    type.instance_eval do
      first_name :string
      last_name :string
      age :int32?
    end
    expect(type.properties.keys).to eq %i[first_name last_name age]
  end

  it 'sets type and required correctly' do
    type = Apigen::ObjectType.new
    type.instance_eval do
      first_name :string
      last_name :string
      age :int32?
    end
    expect(type.properties[:first_name]).to eq(Apigen::ObjectProperty.new(Apigen::PrimaryType.new(:string)).required(true))
    expect(type.properties[:last_name]).to eq(Apigen::ObjectProperty.new(Apigen::PrimaryType.new(:string)).required(true))
    expect(type.properties[:age]).to eq(Apigen::ObjectProperty.new(Apigen::PrimaryType.new(:int32)).required(false))
  end

  it 'sets description and example' do
    type = Apigen::ObjectType.new
    type.instance_eval do
      first_name(:string).explain do
        description 'First name'
      end
      last_name(:string).explain do
        description 'Last name'
        example 'Sinatra'
      end
      (age :int32?).explain do
        example 25
      end
    end
    expect(type.properties[:first_name].description).to eq 'First name'
    expect(type.properties[:first_name].example).to be nil
    expect(type.properties[:last_name].description).to eq 'Last name'
    expect(type.properties[:last_name].example).to be 'Sinatra'
    expect(type.properties[:age].example).to eq 25
  end

  describe '#add' do
    it 'adds properties' do
      type = Apigen::ObjectType.new
      type.add do
        first_name :string
        last_name :string
        age :int32?
      end
      expect(type.properties.keys).to eq %i[first_name last_name age]
    end
  end

  describe '#remove' do
    it 'removes properties' do
      type = Apigen::ObjectType.new
      type.add do
        first_name :string
        last_name :string
        age :int32?
      end
      type.remove :first_name, :age
      expect(type.properties.keys).to eq [:last_name]
    end

    it 'refuses to remove nonexistent properties' do
      type = Apigen::ObjectType.new
      type.add do
        first_name :string
        last_name :string
        age :int32?
      end
      expect do
        type.remove :unknown, :age
      end.to raise_error 'Cannot remove nonexistent property :unknown.'
    end
  end

  describe '#validate' do
    let(:model_registry) { double('model_registry') }

    it 'passes if each property type is valid' do
      type = Apigen::ObjectType.new
      type.add do
        first_name :string
        last_name :string
        age :int32?
      end

      allow(model_registry).to receive(:check_type).with(anything)

      type.validate(model_registry)
    end

    it 'fails if one property type is invalid' do
      type = Apigen::ObjectType.new
      type.add do
        first_name :string
        last_name :string
        age :int32?
      end

      allow(model_registry).to receive(:check_type).with(anything)
      allow(model_registry).to receive(:check_type).with(Apigen::PrimaryType.new(:int32)).and_raise('Error')

      expect do
        type.validate(model_registry)
      end.to raise_error('Error')
    end
  end

  describe '#to_s' do
    it 'generates a reasonable output' do
      type = Apigen::ObjectType.new
      type.add do
        first_name :string
        last_name :string
        age :int32?
        parent :object do
          name :string
        end
      end
      expect(type.to_s).to eq "{
  first_name: string
  last_name: string
  age: int32?
  parent: {
    name: string
  }
}"
    end
  end
end
