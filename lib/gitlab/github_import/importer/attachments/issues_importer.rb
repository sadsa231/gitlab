# frozen_string_literal: true

module Gitlab
  module GithubImport
    module Importer
      module Attachments
        class IssuesImporter < ::Gitlab::GithubImport::Importer::Attachments::BaseImporter
          def sidekiq_worker_class
            ::Gitlab::GithubImport::Attachments::ImportIssueWorker
          end

          def collection_method
            :issue_attachments
          end

          def object_type
            :issue_attachment
          end

          def id_for_already_imported_cache(issue)
            issue.id
          end

          private

          def collection
            project.issues.select(:id, :description)
          end

          def ordering_column
            :iid
          end
        end
      end
    end
  end
end
