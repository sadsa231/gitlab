# frozen_string_literal: true

module Groups
  class UsageQuotasController < Groups::ApplicationController
    before_action :authorize_read_usage_quotas!
    before_action :verify_usage_quotas_enabled!
    before_action :push_frontend_feature_flags

    feature_category :subscription_cost_management
    urgency :low

    def index
      # To be used in ee/app/controllers/ee/groups/usage_quotas_controller.rb
      @seat_count_data = seat_count_data
    end

    private

    def push_frontend_feature_flags
      push_frontend_feature_flag(:usage_quotas_for_all_editions, @group)
    end

    def verify_usage_quotas_enabled!
      render_404 unless group.usage_quotas_enabled?
    end

    # To be overriden in ee/app/controllers/ee/groups/usage_quotas_controller.rb
    def seat_count_data; end
  end
end

Groups::UsageQuotasController.prepend_mod
