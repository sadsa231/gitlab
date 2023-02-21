# frozen_string_literal: true

module Types
  class QueryType < ::Types::BaseObject
    graphql_name 'Query'

    # The design management context object needs to implement #issue
    DesignManagementObject = Struct.new(:issue)

    field :board_list, ::Types::BoardListType,
          null: true,
          resolver: Resolvers::BoardListResolver
    field :ci_application_settings, Types::Ci::ApplicationSettingType,
          null: true,
          description: 'CI related settings that apply to the entire instance.'
    field :ci_config, resolver: Resolvers::Ci::ConfigResolver, complexity: 126 # AUTHENTICATED_MAX_COMPLEXITY / 2 + 1
    field :ci_variables,
          Types::Ci::InstanceVariableType.connection_type,
          null: true,
          description: "List of the instance's CI/CD variables.",
          resolver: Resolvers::Ci::VariablesResolver
    field :container_repository, Types::ContainerRepositoryDetailsType,
          null: true,
          description: 'Find a container repository.' do
            argument :id,
                     type: ::Types::GlobalIDType[::ContainerRepository],
                     required: true,
                     description: 'Global ID of the container repository.'
          end
    field :current_user, Types::UserType,
          null: true,
          description: "Get information about current user."
    field :design_management, Types::DesignManagementType,
          null: false,
          description: 'Fields related to design management.'
    field :echo, resolver: Resolvers::EchoResolver
    field :gitpod_enabled, GraphQL::Types::Boolean,
          null: true,
          description: "Whether Gitpod is enabled in application settings."
    field :group, Types::GroupType,
          null: true,
          resolver: Resolvers::GroupResolver,
          description: "Find a group."
    field :issue, Types::IssueType,
          null: true,
          description: 'Find an issue.' do
            argument :id, ::Types::GlobalIDType[::Issue], required: true, description: 'Global ID of the issue.'
          end
    field :issues,
          null: true,
          alpha: { milestone: '15.6' },
          resolver: Resolvers::IssuesResolver,
          description: 'Find issues visible to the current user.' \
                       ' At least one filter must be provided.'
    field :jobs,
          ::Types::Ci::JobType.connection_type,
          null: true,
          description: 'All jobs on this GitLab instance.',
          resolver: ::Resolvers::Ci::AllJobsResolver
    field :merge_request, Types::MergeRequestType,
          null: true,
          description: 'Find a merge request.' do
            argument :id, ::Types::GlobalIDType[::MergeRequest], required: true, description: 'Global ID of the merge request.'
          end
    field :metadata, Types::MetadataType,
          null: true,
          resolver: Resolvers::MetadataResolver,
          description: 'Metadata about GitLab.'
    field :milestone, ::Types::MilestoneType,
          null: true,
          extras: [:lookahead],
          description: 'Find a milestone.' do
            argument :id, ::Types::GlobalIDType[Milestone], required: true, description: 'Find a milestone by its ID.'
          end
    field :namespace, Types::NamespaceType,
          null: true,
          resolver: Resolvers::NamespaceResolver,
          description: "Find a namespace."
    field :package,
          description: 'Find a package. This field can only be resolved for one query in any single request. Returns `null` if a package has no `default` status.',
          resolver: Resolvers::PackageDetailsResolver
    field :project, Types::ProjectType,
          null: true,
          resolver: Resolvers::ProjectResolver,
          description: "Find a project."
    field :projects, Types::ProjectType.connection_type,
          null: true,
          resolver: Resolvers::ProjectsResolver,
          description: "Find projects visible to the current user."
    field :query_complexity, Types::QueryComplexityType,
          null: true,
          description: 'Information about the complexity of the GraphQL query.'
    field :runner, Types::Ci::RunnerType,
          null: true,
          resolver: Resolvers::Ci::RunnerResolver,
          extras: [:lookahead],
          description: "Find a runner."
    field :runner_platforms, resolver: Resolvers::Ci::RunnerPlatformsResolver,
          deprecated: { reason: 'No longer used, use gitlab-runner documentation to learn about supported platforms', milestone: '15.9' }
    field :runner_setup, resolver: Resolvers::Ci::RunnerSetupResolver,
          deprecated: { reason: 'No longer used, use gitlab-runner documentation to learn about runner registration commands', milestone: '15.9' }
    field :runners, Types::Ci::RunnerType.connection_type,
          null: true,
          resolver: Resolvers::Ci::RunnersResolver,
          description: "Find runners visible to the current user."
    field :snippets,
          Types::SnippetType.connection_type,
          null: true,
          resolver: Resolvers::SnippetsResolver,
          description: 'Find Snippets visible to the current user.'
    field :timelogs, Types::TimelogType.connection_type,
          null: true,
          description: 'Find timelogs visible to the current user.',
          extras: [:lookahead],
          complexity: 5,
          resolver: ::Resolvers::TimelogResolver
    field :todo,
          null: true,
          resolver: Resolvers::TodoResolver
    field :topics, Types::Projects::TopicType.connection_type,
          null: true,
          resolver: Resolvers::TopicsResolver,
          description: "Find project topics."
    field :usage_trends_measurements, Types::Admin::Analytics::UsageTrends::MeasurementType.connection_type,
          null: true,
          description: 'Get statistics on the instance.',
          resolver: Resolvers::Admin::Analytics::UsageTrends::MeasurementsResolver
    field :user, Types::UserType,
          null: true,
          description: 'Find a user.',
          resolver: Resolvers::UserResolver
    field :users, Types::UserType.connection_type,
          null: true,
          description: 'Find users.',
          resolver: Resolvers::UsersResolver
    field :work_item, Types::WorkItemType,
          null: true,
          resolver: Resolvers::WorkItemResolver,
          alpha: { milestone: '15.1' },
          description: 'Find a work item.'

    def design_management
      DesignManagementObject.new(nil)
    end

    def issue(id:)
      GitlabSchema.find_by_gid(id)
    end

    def merge_request(id:)
      GitlabSchema.find_by_gid(id)
    end

    def milestone(id:, lookahead:)
      preloads = [:releases] if lookahead.selects?(:releases)
      Gitlab::Graphql::Loaders::BatchModelLoader.new(id.model_class, id.model_id, preloads).find
    end

    def container_repository(id:)
      GitlabSchema.find_by_gid(id)
    end

    def current_user
      context[:current_user]
    end

    def ci_application_settings
      application_settings
    end

    def application_settings
      Gitlab::CurrentSettings.current_application_settings
    end

    def gitpod_enabled
      application_settings.gitpod_enabled
    end

    def query_complexity
      context.query
    end
  end
end

Types::QueryType.prepend_mod_with('Types::QueryType')
