# frozen_string_literal: true

require 'apigen/models/array_type'

RSpec.describe Apigen::ArrayType do
  let(:model_registry) { double('model_registry') }

  describe '#validate' do
    it 'enforces that a type is set' do
      type = Apigen::ArrayType.new
      expect { type.validate(model_registry) }.to raise_error 'Use `type [typename]` to specify the type of items in an array.'
    end

    it 'fails if model registry check fails' do
      type = Apigen::ArrayType.new(:string)
      allow(model_registry).to receive(:check_type).with(anything).and_raise 'Error'
      expect { type.validate(model_registry) }.to raise_error 'Error'
    end

    it 'passes if model registry check passes' do
      type = Apigen::ArrayType.new(:string)
      allow(model_registry).to receive(:check_type).with(anything)
      type.validate(model_registry)
    end
  end

  describe '#to_s' do
    it 'generates a reasonable output' do
      type = Apigen::ArrayType.new
      type.type :string
      expect(type.to_s).to eq 'ArrayType<string>'

      type = Apigen::ArrayType.new
      type.type :object do
        name :string
      end
      expect(type.to_s).to eq 'ArrayType<{
  name: string
}>'
    end
  end
end
