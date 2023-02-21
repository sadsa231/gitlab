# frozen_string_literal: true

module Mutations
  module Ci
    class ProjectCiCdSettingsUpdate < BaseMutation
      graphql_name 'ProjectCiCdSettingsUpdate'

      include FindsProject

      authorize :admin_project

      argument :full_path, GraphQL::Types::ID,
        required: true,
        description: 'Full Path of the project the settings belong to.'

      argument :keep_latest_artifact, GraphQL::Types::Boolean,
        required: false,
        description: 'Indicates if the latest artifact should be kept for the project.'

      argument :job_token_scope_enabled, GraphQL::Types::Boolean,
        required: false,
        description: 'Indicates CI/CD job tokens generated in this project ' \
          'have restricted access to other projects.'

      argument :inbound_job_token_scope_enabled, GraphQL::Types::Boolean,
        required: false,
        description: 'Indicates CI/CD job tokens generated in other projects ' \
          'have restricted access to this project.'

      argument :opt_in_jwt, GraphQL::Types::Boolean,
        required: false,
        description: 'When disabled, the JSON Web Token is always available in all jobs in the pipeline.'

      field :ci_cd_settings,
        Types::Ci::CiCdSettingType,
        null: false,
        description: 'CI/CD settings after mutation.'

      def resolve(full_path:, **args)
        project = authorized_find!(full_path)

        args.delete(:inbound_job_token_scope_enabled) unless Feature.enabled?(:ci_inbound_job_token_scope, project)

        settings = project.ci_cd_settings
        settings.update(args)

        {
          ci_cd_settings: settings,
          errors: errors_on_object(settings)
        }
      end
    end
  end
end

Mutations::Ci::ProjectCiCdSettingsUpdate.prepend_mod_with('Mutations::Ci::ProjectCiCdSettingsUpdate')
