# frozen_string_literal: true

module Vulnerabilities
  class FindingDismissService < BaseProjectService
    include Gitlab::Allowable

    def initialize(user, finding, comment = nil, dismissal_reason = nil)
      super(project: finding.project, current_user: user)
      @finding = finding
      @comment = comment
      @dismissal_reason = dismissal_reason
    end

    def execute
      return ServiceResponse.error(message: "Access denied", http_status: :forbidden) unless authorized?

      dismiss_finding
    end

    private

    def authorized?
      can?(@current_user, :admin_vulnerability, @project)
    end

    def dismiss_finding
      @error_message = nil

      ApplicationRecord.transaction do
        create_feedback
        create_or_dismiss_vulnerability
      end

      if @error_message
        error_string = _("failed to dismiss finding: %{message}") % { message: @error_message }
        ServiceResponse.error(message: error_string, http_status: :unprocessable_entity)
      else
        ServiceResponse.success(payload: { finding: @finding })
      end
    end

    def create_feedback
      result = ::VulnerabilityFeedback::CreateService.new(
        @project,
        @current_user,
        feedback_params_for(@finding, @comment, @dismissal_reason)
      ).execute

      return if result[:status] == :success

      @error_message = result[:message].full_messages.join(",")
      raise ActiveRecord::Rollback
    end

    def create_or_dismiss_vulnerability
      if @finding.vulnerability_id.nil?
        ::Vulnerabilities::CreateService.new(
          @project,
          @current_user,
          finding_id: @finding.id,
          state: @state,
          present_on_default_branch: false
        ).execute
      else
        vulnerability = Vulnerability.find(@finding.vulnerability_id)
        ::Vulnerabilities::DismissService.new(current_user, vulnerability, @comment, @dismissal_reason).execute
      end
    end

    def feedback_params_for(finding, comment, dismissal_reason)
      {
        category: @finding.report_type,
        feedback_type: 'dismissal',
        project_fingerprint: @finding.project_fingerprint,
        comment: @comment,
        dismissal_reason: @dismissal_reason,
        pipeline: @project.latest_ingested_security_pipeline,
        finding_uuid: @finding.uuid_v5,
        dismiss_vulnerability: false
      }
    end
  end
end
