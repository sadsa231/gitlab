# frozen_string_literal: true

module Ml
  module ExperimentTracking
    class CandidateRepository
      attr_accessor :project, :user, :experiment, :candidate

      def initialize(project, user)
        @project = project
        @user = user
      end

      def by_iid(iid)
        ::Ml::Candidate.with_project_id_and_iid(project.id, iid)
      end

      def create!(experiment, start_time, tags = nil, name = nil)
        candidate = experiment.candidates.create!(
          user: user,
          name: candidate_name(name, tags),
          start_time: start_time || 0
        )

        add_tags(candidate, tags)

        candidate
      end

      def update(candidate, status, end_time)
        candidate.status = status.downcase if status
        candidate.end_time = end_time if end_time

        candidate.save
      end

      def add_metric!(candidate, name, value, tracked_at, step)
        candidate.metrics.create!(
          name: name,
          value: value,
          tracked_at: tracked_at,
          step: step
        )
      end

      def add_param!(candidate, name, value)
        candidate.params.create!(name: name, value: value)
      end

      def add_tag!(candidate, name, value)
        candidate.metadata.create!(name: name, value: value)
      end

      def add_metrics(candidate, metric_definitions)
        extra_keys = { tracked_at: :timestamp, step: :step }
        insert_many(candidate, metric_definitions, ::Ml::CandidateMetric, extra_keys)
      end

      def add_params(candidate, param_definitions)
        insert_many(candidate, param_definitions, ::Ml::CandidateParam)
      end

      def add_tags(candidate, tag_definitions)
        insert_many(candidate, tag_definitions, ::Ml::CandidateMetadata)
      end

      private

      def timestamps
        current_time = Time.zone.now

        { created_at: current_time, updated_at: current_time }
      end

      def insert_many(candidate, definitions, entity_class, extra_keys = {})
        return unless candidate.present? && definitions.present?

        entities = definitions.map do |d|
          {
            candidate_id: candidate.id,
            name: d[:key],
            value: d[:value],
            **extra_keys.transform_values { |old_key| d[old_key] },
            **timestamps
          }
        end

        entity_class.insert_all(entities, returning: false) unless entities.empty?
      end

      def candidate_name(name, tags)
        return name if name.present?
        return unless tags.present?

        tags.detect { |t| t[:key] == 'mlflow.runName' }&.dig(:value)
      end
    end
  end
end
