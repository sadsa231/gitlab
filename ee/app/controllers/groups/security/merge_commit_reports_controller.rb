# frozen_string_literal: true
class Groups::Security::MergeCommitReportsController < Groups::ApplicationController
  include Groups::SecurityFeaturesHelper

  before_action :authorize_compliance_dashboard!

  feature_category :compliance_management

  def index
    MergeCommits::ExportCsvService.new(
      current_user,
      group,
      filter_params
    ).enqueue_worker

    flash[:notice] = _('An email will be sent with the report attached after it is generated.')
    redirect_to group_security_compliance_dashboard_path(group)
  end

  private

  def merge_commits_csv_filename
    "#{group.id}-merge-commits-#{Time.current.to_i}.csv"
  end

  def filter_params
    params.permit(:commit_sha)
  end
end
