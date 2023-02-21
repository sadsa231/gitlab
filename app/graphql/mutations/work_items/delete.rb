# frozen_string_literal: true

module Mutations
  module WorkItems
    class Delete < BaseMutation
      graphql_name 'WorkItemDelete'
      description "Deletes a work item."

      authorize :delete_work_item

      argument :id, ::Types::GlobalIDType[::WorkItem],
               required: true,
               description: 'Global ID of the work item.'

      field :project, Types::ProjectType,
            null: true,
            description: 'Project the deleted work item belonged to.'

      def resolve(id:)
        work_item = authorized_find!(id: id)

        result = ::WorkItems::DeleteService.new(
          project: work_item.project,
          current_user: current_user
        ).execute(work_item)

        {
          project: result.success? ? work_item.project : nil,
          errors: result.errors
        }
      end

      private

      def find_object(id:)
        GitlabSchema.find_by_gid(id)
      end
    end
  end
end
