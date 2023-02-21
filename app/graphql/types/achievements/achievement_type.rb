# frozen_string_literal: true

module Types
  module Achievements
    class AchievementType < BaseObject
      graphql_name 'Achievement'

      authorize :read_achievement

      field :id,
            ::Types::GlobalIDType[::Achievements::Achievement],
            null: false,
            description: 'ID of the achievement.'

      field :namespace,
            ::Types::NamespaceType,
            null: false,
            description: 'Namespace of the achievement.'

      field :name,
            GraphQL::Types::String,
            null: false,
            description: 'Name of the achievement.'

      field :avatar_url,
            GraphQL::Types::String,
            null: true,
            description: 'URL to avatar of the achievement.'

      field :description,
            GraphQL::Types::String,
            null: true,
            description: 'Description or notes for the achievement.'

      field :revokeable,
            GraphQL::Types::Boolean,
            null: false,
            description: 'Revokeability of the achievement.'

      field :created_at,
            Types::TimeType,
            null: false,
            description: 'Timestamp the achievement was created.'

      field :updated_at,
            Types::TimeType,
            null: false,
            description: 'Timestamp the achievement was last updated.'

      def avatar_url
        object.avatar_url(only_path: false)
      end
    end
  end
end
