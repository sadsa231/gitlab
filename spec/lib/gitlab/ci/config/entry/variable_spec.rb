# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Config::Entry::Variable do
  let(:config) { {} }
  let(:metadata) { {} }

  subject(:entry) do
    described_class.new(config, **metadata).tap do |entry|
      entry.key = 'VAR1' # composable_hash requires key to be set
    end
  end

  before do
    entry.compose!
  end

  describe 'SimpleVariable' do
    context 'when config is a string' do
      let(:config) { 'value' }

      describe '#valid?' do
        it { is_expected.to be_valid }
      end

      describe '#value' do
        subject(:value) { entry.value }

        it { is_expected.to eq('value') }
      end
    end

    context 'when config is an integer' do
      let(:config) { 1 }

      describe '#valid?' do
        it { is_expected.to be_valid }
      end

      describe '#value' do
        subject(:value) { entry.value }

        it { is_expected.to eq('1') }
      end
    end

    context 'when config is an array' do
      let(:config) { [] }

      describe '#valid?' do
        it { is_expected.not_to be_valid }
      end

      describe '#errors' do
        subject(:errors) { entry.errors }

        it { is_expected.to include 'variable definition must be either a string or a hash' }
      end
    end
  end

  describe 'ComplexVariable' do
    context 'when config is a hash with description' do
      let(:config) { { value: 'value', description: 'description' } }

      context 'when metadata allowed_value_data is not provided' do
        describe '#valid?' do
          it { is_expected.not_to be_valid }
        end

        describe '#errors' do
          subject(:errors) { entry.errors }

          it { is_expected.to include 'var1 config must be a string' }
        end
      end

      context 'when metadata allowed_value_data is (value, description)' do
        let(:metadata) { { allowed_value_data: %i[value description] } }

        describe '#valid?' do
          it { is_expected.to be_valid }
        end

        describe '#value' do
          subject(:value) { entry.value }

          it { is_expected.to eq('value') }
        end

        describe '#value_with_data' do
          subject(:value_with_data) { entry.value_with_data }

          it { is_expected.to eq(value: 'value') }
        end

        describe '#value_with_prefill_data' do
          subject(:value_with_prefill_data) { entry.value_with_prefill_data }

          it { is_expected.to eq(value: 'value', description: 'description') }
        end

        context 'when config value is a symbol' do
          let(:config) { { value: :value, description: 'description' } }

          describe '#value' do
            subject(:value) { entry.value }

            it { is_expected.to eq('value') }
          end

          describe '#value_with_data' do
            subject(:value_with_data) { entry.value_with_data }

            it { is_expected.to eq(value: 'value') }
          end

          describe '#value_with_prefill_data' do
            subject(:value_with_prefill_data) { entry.value_with_prefill_data }

            it { is_expected.to eq(value: 'value', description: 'description') }
          end
        end

        context 'when config value is an integer' do
          let(:config) { { value: 123, description: 'description' } }

          describe '#value' do
            subject(:value) { entry.value }

            it { is_expected.to eq('123') }
          end

          describe '#value_with_data' do
            subject(:value_with_data) { entry.value_with_data }

            it { is_expected.to eq(value: '123') }
          end

          describe '#value_with_prefill_data' do
            subject(:value_with_prefill_data) { entry.value_with_prefill_data }

            it { is_expected.to eq(value: '123', description: 'description') }
          end
        end

        context 'when config description is a symbol' do
          let(:config) { { value: 'value', description: :description } }

          describe '#value' do
            subject(:value) { entry.value }

            it { is_expected.to eq('value') }
          end

          describe '#value_with_data' do
            subject(:value_with_data) { entry.value_with_data }

            it { is_expected.to eq(value: 'value') }
          end

          describe '#value_with_prefill_data' do
            subject(:value_with_prefill_data) { entry.value_with_prefill_data }

            it { is_expected.to eq(value: 'value', description: :description) }
          end
        end
      end

      context 'when metadata allowed_value_data is (value, xyz)' do
        let(:metadata) { { allowed_value_data: %i[value xyz] } }

        describe '#valid?' do
          it { is_expected.not_to be_valid }
        end

        describe '#errors' do
          subject(:errors) { entry.errors }

          it { is_expected.to include 'var1 config uses invalid data keys: description' }
        end
      end
    end

    context 'when config is a hash without description' do
      let(:config) { { value: 'value' } }

      context 'when metadata allowed_value_data is not provided' do
        describe '#valid?' do
          it { is_expected.not_to be_valid }
        end

        describe '#errors' do
          subject(:errors) { entry.errors }

          it { is_expected.to include 'var1 config must be a string' }
        end
      end

      context 'when metadata allowed_value_data is (value, description)' do
        let(:metadata) { { allowed_value_data: %i[value description] } }

        describe '#valid?' do
          it { is_expected.to be_valid }
        end

        describe '#value' do
          subject(:value) { entry.value }

          it { is_expected.to eq('value') }
        end

        describe '#value_with_data' do
          subject(:value_with_data) { entry.value_with_data }

          it { is_expected.to eq(value: 'value') }
        end

        describe '#value_with_prefill_data' do
          subject(:value_with_prefill_data) { entry.value_with_prefill_data }

          it { is_expected.to eq(value: 'value') }
        end
      end
    end

    context 'when config is a hash with expand' do
      let(:config) { { value: 'value', expand: false } }

      context 'when metadata allowed_value_data is not provided' do
        describe '#valid?' do
          it { is_expected.not_to be_valid }
        end

        describe '#errors' do
          subject(:errors) { entry.errors }

          it { is_expected.to include 'var1 config must be a string' }
        end
      end

      context 'when metadata allowed_value_data is (value, expand)' do
        let(:metadata) { { allowed_value_data: %i[value expand] } }

        describe '#valid?' do
          it { is_expected.to be_valid }
        end

        describe '#value' do
          subject(:value) { entry.value }

          it { is_expected.to eq('value') }
        end

        describe '#value_with_data' do
          subject(:value_with_data) { entry.value_with_data }

          it { is_expected.to eq(value: 'value', raw: true) }
        end

        context 'when config expand is true' do
          let(:config) { { value: 'value', expand: true } }

          describe '#value_with_data' do
            subject(:value_with_data) { entry.value_with_data }

            it { is_expected.to eq(value: 'value', raw: false) }
          end
        end

        context 'when config expand is a string' do
          let(:config) { { value: 'value', expand: "true" } }

          describe '#valid?' do
            it { is_expected.not_to be_valid }
          end

          describe '#errors' do
            subject(:errors) { entry.errors }

            it { is_expected.to include 'var1 config expand should be a boolean value' }
          end
        end
      end

      context 'when metadata allowed_value_data is (value, xyz)' do
        let(:metadata) { { allowed_value_data: %i[value xyz] } }

        describe '#valid?' do
          it { is_expected.not_to be_valid }
        end

        describe '#errors' do
          subject(:errors) { entry.errors }

          it { is_expected.to include 'var1 config uses invalid data keys: expand' }
        end
      end
    end

    context 'when config is a hash with options' do
      context 'when there is no metadata' do
        let(:config) { { value: 'value', options: %w[value value2] } }
        let(:metadata) { {} }

        describe '#valid?' do
          it { is_expected.not_to be_valid }
        end

        describe '#errors' do
          subject(:errors) { entry.errors }

          it { is_expected.to include 'var1 config must be a string' }
        end
      end

      context 'when options are allowed' do
        let(:config) { { value: 'value', options: %w[value value2] } }
        let(:metadata) { { allowed_value_data: %i[value options] } }

        describe '#valid?' do
          it { is_expected.to be_valid }
        end

        describe '#value' do
          subject(:value) { entry.value }

          it { is_expected.to eq('value') }
        end

        describe '#value_with_data' do
          subject(:value_with_data) { entry.value_with_data }

          it { is_expected.to eq(value: 'value') }
        end

        describe '#value_with_prefill_data' do
          subject(:value_with_prefill_data) { entry.value_with_prefill_data }

          it { is_expected.to eq(value: 'value', options: %w[value value2]) }
        end
      end
    end
  end
end
