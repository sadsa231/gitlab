# frozen_string_literal: true

module Gitlab
  module GithubImport
    module Stage
      class ImportPullRequestsReviewRequestsWorker # rubocop:disable Scalability/IdempotentWorker
        include ApplicationWorker

        data_consistency :always

        sidekiq_options retry: 3
        include GithubImport::Queue
        include StageMethods

        # client - An instance of Gitlab::GithubImport::Client.
        # project - An instance of Project.
        def import(client, project)
          waiter = Importer::PullRequests::ReviewRequestsImporter
           .new(project, client)
           .execute

          project.import_state.refresh_jid_expiration

          AdvanceStageWorker.perform_async(
            project.id,
            { waiter.key => waiter.jobs_remaining },
            :pull_request_reviews
          )
        end
      end
    end
  end
end
