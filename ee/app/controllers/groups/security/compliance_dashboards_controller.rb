# frozen_string_literal: true
class Groups::Security::ComplianceDashboardsController < Groups::ApplicationController
  include Groups::SecurityFeaturesHelper
  include ProductAnalyticsTracking

  layout 'group'

  before_action :authorize_compliance_dashboard!
  before_action do
    push_frontend_feature_flag(:all_commits_compliance_report, group)
  end

  track_custom_event :show,
    name: 'g_compliance_dashboard',
    action: 'show_compliance_dashboard',
    label: 'redis_hll_counters.compliance.g_compliance_dashboard_monthly',
    destinations: [:redis_hll, :snowplow]

  feature_category :compliance_management

  def show; end

  def tracking_namespace_source
    group
  end

  def tracking_project_source
    nil
  end
end
