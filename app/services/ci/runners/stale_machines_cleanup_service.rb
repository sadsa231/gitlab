# frozen_string_literal: true

module Ci
  module Runners
    class StaleMachinesCleanupService
      MAX_DELETIONS = 1000

      def execute
        ServiceResponse.success(payload: {
          # the `stale` relationship can return duplicates, so we don't try to return a precise count here
          deleted_machines: delete_stale_runner_machines > 0
        })
      end

      private

      def delete_stale_runner_machines
        total_deleted_count = 0
        loop do
          sub_batch_limit = [100, MAX_DELETIONS].min

          # delete_all discards part of the `stale` scope query, so we expliclitly wrap it with a SELECT as a workaround
          deleted_count = Ci::RunnerMachine.id_in(Ci::RunnerMachine.stale.limit(sub_batch_limit)).delete_all
          total_deleted_count += deleted_count

          break if deleted_count == 0 || total_deleted_count >= MAX_DELETIONS
        end

        total_deleted_count
      end
    end
  end
end
