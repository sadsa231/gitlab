# frozen_string_literal: true

module RuboCop
  module Cop
    module Rake
      # Flag global `require`s or `require_relative`s in rake files.
      #
      # Load dependencies lazily in `task` definitions if possible.
      #
      # @example
      #   # bad
      #
      #   require_relative 'gitlab/json'
      #   require 'json'
      #
      #   task :parse_json do
      #     Gitlab::Json.parse(...)
      #   end
      #
      #   # good
      #
      #   task :parse_json do
      #     require_relative 'gitlab/json'
      #     require 'json'
      #
      #     Gitlab::Json.parse(...)
      #   end
      #
      #   RSpec::Core::RakeTask.new(:parse_json) do |t, args|
      #     require_relative 'gitlab/json'
      #     require 'json'
      #
      #     Gitlab::Json.parse(...)
      #   end
      #
      #   # Requiring files which contain the word `task` is allowed.
      #   require 'some_gem/rake_task'
      #   require 'some_gem/rake_tasks'
      #
      #   SomeGem.define_tasks
      #
      #   # Loading in method definition as well.
      #   def load_deps
      #     require 'json'
      #   end
      #
      #   task :parse_json
      #     load_deps
      #   end
      #
      class Require < RuboCop::Cop::Base
        MSG = 'Load dependencies inside `task` definitions if possible.'

        METHODS = %i[require require_relative].freeze
        RESTRICT_ON_SEND = METHODS

        def_node_matcher :require_method, <<~PATTERN
          (send nil? ${#{METHODS.map(&:inspect).join(' ')}} $_)
        PATTERN

        def on_send(node)
          method, file = require_method(node)
          return unless method

          return if requires_task?(file)
          return if inside_block_or_method?(node)

          add_offense(node)
        end

        private

        # Allow `require "foo/rake_task"`
        def requires_task?(file)
          file.source.include?('task')
        end

        def inside_block_or_method?(node)
          node.each_ancestor(:block, :def).any?
        end
      end
    end
  end
end
