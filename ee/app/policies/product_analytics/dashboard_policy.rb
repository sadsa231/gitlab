# frozen_string_literal: true

module ProductAnalytics
  class DashboardPolicy < BasePolicy
    delegate { @subject.project }
  end
end
