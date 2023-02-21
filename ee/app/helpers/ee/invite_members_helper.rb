# frozen_string_literal: true

module EE
  module InviteMembersHelper
    extend ::Gitlab::Utils::Override

    override :common_invite_group_modal_data
    def common_invite_group_modal_data(source, _member_class, _is_project)
      super.merge(
        free_user_cap_enabled: ::Namespaces::FreeUserCap.notification_or_enforcement_enabled?(
          source.root_ancestor
        ).to_s,
        free_users_limit: ::Namespaces::FreeUserCap.dashboard_limit
      )
    end

    override :common_invite_modal_dataset
    def common_invite_modal_dataset(source)
      dataset = super

      free_user_cap = ::Namespaces::FreeUserCap::Enforcement.new(source.root_ancestor)
      notification_free_user_cap = ::Namespaces::FreeUserCap::Notification.new(source.root_ancestor)

      return dataset unless free_user_cap.enforce_cap? || notification_free_user_cap.enforce_cap?

      alert_variant =
        if free_user_cap.enforce_cap?
          if free_user_cap.reached_limit?
            ::Namespaces::FreeUserCap::REACHED_LIMIT_VARIANT
          elsif free_user_cap.close_to_dashboard_limit?
            ::Namespaces::FreeUserCap::CLOSE_TO_LIMIT_VARIANT
          end
        elsif notification_free_user_cap.over_limit?
          ::Namespaces::FreeUserCap::NOTIFICATION_LIMIT_VARIANT
        end

      dataset.merge(
        users_limit_dataset: ::Gitlab::Json.dump(
          {
            alert_variant: alert_variant,
            new_trial_registration_path: new_trial_path,
            members_path: group_usage_quotas_path(source.root_ancestor),
            purchase_path: group_billings_path(source.root_ancestor),
            remaining_seats: free_user_cap.remaining_seats,
            free_users_limit: ::Namespaces::FreeUserCap.dashboard_limit
          }
        )
      )
    end

    override :users_filter_data
    def users_filter_data(group)
      root_group = group&.root_ancestor

      return {} unless root_group&.enforced_sso? && root_group.saml_provider&.id

      { users_filter: 'saml_provider_id', filter_id: root_group.saml_provider.id }
    end

    private

    override :show_invite_members_for_task?
    def show_invite_members_for_task?(source)
      invite_for_help_continuous_onboarding = source.is_a?(Project) &&
        experiment(:invite_for_help_continuous_onboarding, namespace: source.namespace).assigned.name == 'candidate'

      super || invite_for_help_continuous_onboarding
    end
  end
end
