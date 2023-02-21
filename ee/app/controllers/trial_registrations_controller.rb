# frozen_string_literal: true

# EE:SaaS
# TODO: namespace https://gitlab.com/gitlab-org/gitlab/-/issues/338394
class TrialRegistrationsController < RegistrationsController
  include OneTrustCSP
  include BizibleCSP
  include GoogleAnalyticsCSP

  layout 'minimal'

  skip_before_action :require_no_authentication

  before_action :check_if_gl_com_or_dev
  before_action :redirect_to_trial_or_store_location, only: [:new]
  before_action only: [:new] do
    push_frontend_feature_flag(:gitlab_gtm_datalayer, type: :ops)
    push_frontend_feature_flag(:trial_email_validation, type: :development)
  end

  def new
  end

  private

  def redirect_to_trial_or_store_location
    if user_signed_in?
      redirect_to new_trial_url(params: request.query_parameters)
    else
      store_location_for(:user, new_users_sign_up_company_path(glm_tracking_params.merge(trial: true)))
    end
  end

  def sign_up_params
    if params[:user]
      params.require(:user).permit(*sign_up_params_attributes)
    else
      {}
    end
  end

  def sign_up_params_attributes
    [:first_name, :last_name, :username, :email, :password, :skip_confirmation, :email_opted_in]
  end

  def resource
    @resource ||= Users::AuthorizedBuildService.new(current_user, sign_up_params).execute
  end
end

TrialRegistrationsController.prepend_mod
