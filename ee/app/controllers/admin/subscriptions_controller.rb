# frozen_string_literal: true

# EE:Self Managed
class Admin::SubscriptionsController < Admin::ApplicationController
  respond_to :html

  feature_category :sm_provisioning
  urgency :low

  def show
    @content_class = 'limit-container-width'
  end
end
