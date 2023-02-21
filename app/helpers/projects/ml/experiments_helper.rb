# frozen_string_literal: true
module Projects
  module Ml
    module ExperimentsHelper
      require 'json'
      include ActionView::Helpers::NumberHelper

      def candidates_table_items(candidates)
        items = candidates.map do |candidate|
          {
            **candidate.params.to_h { |p| [p.name, p.value] },
            **candidate.latest_metrics.to_h { |m| [m.name, number_with_precision(m.value, precision: 4)] },
            artifact: link_to_artifact(candidate),
            details: link_to_details(candidate),
            name: candidate.name,
            created_at: candidate.created_at,
            user: user_info(candidate)
          }
        end

        Gitlab::Json.generate(items)
      end

      def unique_logged_names(candidates, &selector)
        Gitlab::Json.generate(candidates.flat_map(&selector).map(&:name).uniq)
      end

      def candidate_as_data(candidate)
        data = {
          params: candidate.params,
          metrics: candidate.latest_metrics,
          info: {
            iid: candidate.iid,
            path_to_artifact: link_to_artifact(candidate),
            experiment_name: candidate.experiment.name,
            path_to_experiment: link_to_experiment(candidate),
            status: candidate.status
          },
          metadata: candidate.metadata
        }

        Gitlab::Json.generate(data)
      end

      def page_info(paginator)
        {
          has_next_page: paginator.has_next_page?,
          has_previous_page: paginator.has_previous_page?,
          start_cursor: paginator.cursor_for_previous_page,
          end_cursor: paginator.cursor_for_next_page
        }
      end

      def formatted_page_info(page_info)
        Gitlab::Json.generate(page_info)
      end

      def link_to_artifact(candidate)
        artifact = candidate.artifact

        return unless artifact.present?

        project_package_path(candidate.project, artifact)
      end

      def link_to_details(candidate)
        project_ml_candidate_path(candidate.project, candidate.iid)
      end

      def link_to_experiment(candidate)
        experiment = candidate.experiment

        project_ml_experiment_path(experiment.project, experiment.iid)
      end

      def user_info(candidate)
        user = candidate.user

        return unless user.present?

        {
          username: user.username,
          path: user_path(user)
        }
      end
    end
  end
end
