# frozen_string_literal: true

require 'rubocop_spec_helper'
require 'rspec-parameterized'

require_relative '../../../../rubocop/cop/rspec/invalid_feature_category'

RSpec.describe RuboCop::Cop::RSpec::InvalidFeatureCategory, feature_category: :tooling do
  shared_examples 'feature category validation' do |valid_category|
    it 'flags invalid feature category in top level example group' do
      expect_offense(<<~RUBY, invalid: invalid_category)
      RSpec.describe 'foo', feature_category: :%{invalid}, foo: :bar do
                                              ^^{invalid} Please use a valid feature category. See https://docs.gitlab.com/ee/development/feature_categorization/#rspec-examples.
      end
      RUBY
    end

    it 'flags invalid feature category in nested context' do
      expect_offense(<<~RUBY, valid: valid_category, invalid: invalid_category)
      RSpec.describe 'foo', feature_category: :%{valid} do
        context 'bar', foo: :bar, feature_category: :%{invalid} do
                                                    ^^{invalid} Please use a valid feature category. See https://docs.gitlab.com/ee/development/feature_categorization/#rspec-examples.
        end
      end
      RUBY
    end

    it 'flags invalid feature category in examples' do
      expect_offense(<<~RUBY, valid: valid_category, invalid: invalid_category)
      RSpec.describe 'foo', feature_category: :%{valid} do
        it 'bar', feature_category: :%{invalid} do
                                    ^^{invalid} Please use a valid feature category. See https://docs.gitlab.com/ee/development/feature_categorization/#rspec-examples.
        end
      end
      RUBY
    end

    it 'does not flag if feature category is valid' do
      expect_no_offenses(<<~RUBY)
      RSpec.describe 'foo', feature_category: :#{valid_category} do
        context 'bar', feature_category: :#{valid_category} do
          it 'baz', feature_category: :#{valid_category} do
          end
        end
      end
      RUBY
    end
  end

  let(:invalid_category) { :invalid_category }

  context 'with categories defined in config/feature_categories.yml' do
    where(:valid_category) do
      YAML.load_file(rails_root_join('config/feature_categories.yml'))
    end

    with_them do
      it_behaves_like 'feature category validation', params[:valid_category]
    end
  end

  context 'with custom categories' do
    it_behaves_like 'feature category validation', 'tooling'
  end

  it 'flags invalid feature category for non-symbols' do
    expect_offense(<<~RUBY, invalid: invalid_category)
      RSpec.describe 'foo', feature_category: "%{invalid}" do
                                              ^^^{invalid} Please use a symbol as value.
      end

      RSpec.describe 'foo', feature_category: 42 do
                                              ^^ Please use a symbol as value.
      end
    RUBY
  end

  describe '#external_dependency_checksum' do
    it 'returns a SHA256 digest used by RuboCop to invalid cache' do
      expect(cop.external_dependency_checksum).to match(/^\h{64}$/)
    end
  end
end
