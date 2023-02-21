# frozen_string_literal: true

module Ci
  class PipelineScheduleService < BaseService
    def execute(schedule)
      return unless project.persisted?

      # Ensure `next_run_at` is set properly before creating a pipeline.
      # Otherwise, multiple pipelines could be created in a short interval.
      schedule.schedule_next_run!
      RunPipelineScheduleWorker.perform_async(schedule.id, current_user&.id, next_run_scheduled: true)
    end
  end
end
