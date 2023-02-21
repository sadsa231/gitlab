# frozen_string_literal: true

module Namespaces
  # This worker can be called multiple times at the same time but only one of them can
  # process events at a time. This is ensured by `try_obtain_lease` in `Ci::ProcessSyncEventsService`.
  # `until_executing` here is to reduce redundant worker enqueuing.
  class ProcessSyncEventsWorker
    include ApplicationWorker

    data_consistency :always

    feature_category :pods
    urgency :high

    idempotent!
    deduplicate :until_executed, if_deduplicated: :reschedule_once

    def perform
      results = ::Ci::ProcessSyncEventsService.new(
        ::Namespaces::SyncEvent, ::Ci::NamespaceMirror
      ).execute

      results.each do |key, value|
        log_extra_metadata_on_done(key, value)
      end
    end
  end
end
