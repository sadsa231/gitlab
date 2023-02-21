# frozen_string_literal: true

module Projects
  class DependenciesController < Projects::ApplicationController
    include SecurityAndCompliancePermissions

    before_action :authorize_read_dependency_list!

    feature_category :dependency_management
    urgency :low

    before_action do
      push_frontend_feature_flag(:dependency_list_exporter, project)
    end

    def index
      respond_to do |format|
        format.html do
          render status: :ok
        end
        format.json do
          render json: serializer.represent(dependencies, build: report_service.build)
        end
      end
    end

    private

    def not_able_to_collect_dependencies?
      !report_service.able_to_fetch? || user_requested_filters_that_they_cannot_see?
    end

    def user_requested_filters_that_they_cannot_see?
      params[:filter] == 'vulnerable' && !can?(current_user, :read_security_resource, project)
    end

    def collect_dependencies
      return [] if not_able_to_collect_dependencies?

      ::Security::DependencyListService.new(pipeline: pipeline, params: dependency_list_params).execute
    end

    def authorize_read_dependency_list!
      render_not_authorized unless can?(current_user, :read_dependencies, project)
    end

    def dependencies
      @dependencies ||= ::Gitlab::ItemsCollection.new(collect_dependencies)
    end

    def pipeline
      @pipeline ||= report_service.pipeline
    end

    def dependency_list_params
      params.permit(:sort_by, :sort, :filter)
    end

    def report_service
      job_artifacts = ::Ci::JobArtifact.of_report_type(:dependency_list)
      @report_service ||= ::Security::ReportFetchService.new(project, job_artifacts)
    end

    def serializer
      serializer = ::DependencyListSerializer.new(project: project, user: current_user)

      if params[:page] || Feature.enabled?(:dependency_list_exporter, project)
        serializer = serializer.with_pagination(request, response)
      end

      serializer
    end

    def render_not_authorized
      respond_to do |format|
        format.html do
          render_404
        end
        format.json do
          render_403
        end
      end
    end
  end
end
