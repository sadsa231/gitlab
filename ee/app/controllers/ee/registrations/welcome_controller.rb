# frozen_string_literal: true

module EE
  module Registrations
    module WelcomeController
      extend ActiveSupport::Concern
      extend ::Gitlab::Utils::Override
      include ::Gitlab::Utils::StrongMemoize

      prepended do
        include OneTrustCSP
        include GoogleAnalyticsCSP
        include Onboarding::SetRedirect

        before_action only: [:continuous_onboarding_getting_started, :show] do
          push_frontend_feature_flag(:gitlab_gtm_datalayer, type: :ops)
        end
      end

      def continuous_onboarding_getting_started
        project = ::Project.find(params[:project_id])
        return access_denied! unless can?(current_user, :owner_access, project)

        cookies[:confetti_post_signup] = true

        label = helpers.in_trial_onboarding_flow? ? 'trial_registration' : 'free_registration'
        track_event('render', label)

        render locals: { project: project, track_label: label }
      end

      private

      def redirect_to_company_form?
        update_params[:setup_for_company] == 'true'
      end

      override :update_params
      def update_params
        clean_params = super.merge(params.require(:user).permit(:email_opted_in, :registration_objective))

        return clean_params unless ::Gitlab.com?

        clean_params[:email_opted_in] = '1' if clean_params[:setup_for_company] == 'true'

        if clean_params[:email_opted_in] == '1'
          clean_params[:email_opted_in_ip] = request.remote_ip
          clean_params[:email_opted_in_source_id] = User::EMAIL_OPT_IN_SOURCE_ID_GITLAB_COM
          clean_params[:email_opted_in_at] = Time.zone.now
        end

        clean_params
      end

      override :redirect_to_signup_onboarding?
      def redirect_to_signup_onboarding?
        !helpers.in_subscription_flow? &&
          !helpers.user_has_memberships? &&
          !helpers.in_oauth_flow? &&
          !helpers.in_trial_flow? &&
          helpers.signup_onboarding_enabled?
      end

      def passed_through_params
        update_params.slice(:role, :registration_objective)
                     .merge(params.permit(:jobs_to_be_done_other))
                     .merge(glm_tracking_params)
      end

      override :signup_onboarding_path
      def signup_onboarding_path
        if params[:joining_project] == 'true'
          finish_onboarding
          path_for_signed_in_user(current_user)
        elsif redirect_to_company_form?
          path = new_users_sign_up_company_path(passed_through_params)
          save_onboarding_step_url(path)
          path
        else
          path = new_users_sign_up_groups_project_path
          save_onboarding_step_url(path)
          path
        end
      end

      override :path_for_signed_in_user
      def path_for_signed_in_user(user)
        return users_almost_there_path(email: user.email) if requires_confirmation?(user)

        stored_url = stored_location_for(user)

        return members_activity_path(user.members) unless stored_url.present?
        return stored_url unless stored_url.include?(new_users_sign_up_company_path)

        redirect_uri = ::Gitlab::Utils.add_url_parameters(stored_url, passed_through_params)
        save_onboarding_step_url(redirect_uri)
        redirect_uri
      end

      override :track_event
      def track_event(action, label = tracking_label)
        ::Gitlab::Tracking.event(
          helpers.body_data_page,
          action,
          user: current_user,
          label: label
        )
      end

      def tracking_label
        return 'trial_registration' if helpers.in_trial_flow?
        return 'invite_registration' if helpers.user_has_memberships?

        'free_registration'
      end
    end
  end
end
