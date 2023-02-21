# frozen_string_literal: true

module ProductAnalytics
  class InitializeStackService < BaseContainerService
    def execute
      unless Gitlab::CurrentSettings.product_analytics_enabled?
        return ServiceResponse.error(message: 'Product analytics is disabled')
      end

      unless container.product_analytics_enabled?
        return ServiceResponse.error(message: 'Product analytics is disabled for this project')
      end

      return ServiceResponse.error(message: 'Product analytics initialization is already in progress') if locked?

      if container.project_setting.jitsu_key.present?
        return ServiceResponse.error(message: 'Product analytics initialization is already complete')
      end

      lock!
      ::ProductAnalytics::InitializeAnalyticsWorker.perform_async(container.id)
      ServiceResponse.success(message: 'Product analytics initialization started')
    end

    def lock!
      Gitlab::Redis::SharedState.with { |redis| redis.set(redis_key, 1) }
    end

    def unlock!
      Gitlab::Redis::SharedState.with { |redis| redis.del(redis_key) }
    end

    private

    def redis_key
      "project:#{container.id}:product_analytics_initializing"
    end

    def locked?
      !!Gitlab::Redis::SharedState.with { |redis| redis.get(redis_key) }
    end
  end
end
