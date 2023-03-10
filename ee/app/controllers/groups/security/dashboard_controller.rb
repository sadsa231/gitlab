# frozen_string_literal: true
class Groups::Security::DashboardController < Groups::ApplicationController
  layout 'group'

  feature_category :vulnerability_management
  urgency :low

  def show
    render :unavailable unless dashboard_available?
  end

  private

  def dashboard_available?
    can?(current_user, :read_group_security_dashboard, group)
  end
end
