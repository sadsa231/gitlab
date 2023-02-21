# frozen_string_literal: true

require 'rubocop/cop/rspec/base'
require 'rubocop/cop/rspec/mixin/top_level_group'

module RuboCop
  module Cop
    module RSpec
      # Ensures that feature categories in specs are valid.
      #
      # @example
      #
      #   # bad
      #   RSpec.describe 'foo', feature_category: :invalid do
      #   end
      #
      #   RSpec.describe 'foo', feature_category: :not_owned do
      #   end
      #
      #   # good
      #
      #   RSpec.describe 'foo', feature_category: :wiki do
      #   end
      #
      #   RSpec.describe 'foo', feature_category: :tooling do
      #   end
      #
      class InvalidFeatureCategory < RuboCop::Cop::RSpec::Base
        MSG = 'Please use a valid feature category. ' \
              'See https://docs.gitlab.com/ee/development/feature_categorization/#rspec-examples.'

        MSG_SYMBOL = 'Please use a symbol as value.'

        FEATURE_CATEGORIES_PATH = File.expand_path('../../../config/feature_categories.yml', __dir__).freeze

        # List of feature categories which are not defined in config/feature_categories.yml
        CUSTOM_FEATURE_CATEGORIES = [
          # https://docs.gitlab.com/ee/development/feature_categorization/#tooling-feature-category
          :tooling
        ].to_set.freeze

        # @!method feature_category?(node)
        def_node_matcher :feature_category_value, <<~PATTERN
          (block
            (send ...
              (hash <(pair (sym :feature_category) $_) ...>)
            )
            ...
          )
        PATTERN

        def on_block(node)
          value_node = feature_category_value(node)
          return unless value_node

          unless value_node.sym_type?
            add_offense(value_node, message: MSG_SYMBOL)
            return
          end

          return if valid_feature_category?(value_node)

          add_offense(value_node)
        end

        # Used by RuboCop to invalidate its cache if the contents of
        # config/feature_categories.json changes.
        def external_dependency_checksum
          @external_dependency_checksum ||=
            Digest::SHA256.file(FEATURE_CATEGORIES_PATH).hexdigest
        end

        private

        def valid_feature_category?(node)
          CUSTOM_FEATURE_CATEGORIES.include?(node.value) ||
            self.class.feature_categories.include?(node.value)
        end

        def self.feature_categories
          @feature_categories ||= YAML
            .load_file(FEATURE_CATEGORIES_PATH)
            .map(&:to_sym)
            .to_set
        end
      end
    end
  end
end
