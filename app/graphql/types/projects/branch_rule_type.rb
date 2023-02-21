# frozen_string_literal: true

module Types
  module Projects
    class BranchRuleType < BaseObject
      graphql_name 'BranchRule'
      description 'List of branch rules for a project, grouped by branch name.'
      authorize :read_protected_branch

      alias_method :branch_rule, :object

      field :name,
            type: GraphQL::Types::String,
            null: false,
            description: 'Branch name, with wildcards, for the branch rules.'

      field :is_default,
            type: GraphQL::Types::Boolean,
            null: false,
            method: :default_branch?,
            calls_gitaly: true,
            description: "Check if this branch rule protects the project's default branch."

      field :is_protected,
            type: GraphQL::Types::Boolean,
            null: false,
            method: :protected?,
            description: "Check if this branch rule protects access for the branch."

      field :matching_branches_count,
            type: GraphQL::Types::Int,
            null: false,
            calls_gitaly: true,
            description: 'Number of existing branches that match this branch rule.'

      field :branch_protection,
            type: Types::BranchRules::BranchProtectionType,
            null: true,
            description: 'Branch protections configured for this branch rule.'

      field :created_at,
            Types::TimeType,
            null: false,
            description: 'Timestamp of when the branch rule was created.'

      field :updated_at,
            Types::TimeType,
            null: false,
            description: 'Timestamp of when the branch rule was last updated.'
    end
  end
end

Types::Projects::BranchRuleType.prepend_mod
