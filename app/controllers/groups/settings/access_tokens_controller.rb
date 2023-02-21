# frozen_string_literal: true

module Groups
  module Settings
    class AccessTokensController < Groups::ApplicationController
      include RenderAccessTokens
      include AccessTokensActions

      layout 'group_settings'
      feature_category :authentication_and_authorization

      alias_method :resource, :group

      def resource_access_tokens_path
        group_settings_access_tokens_path
      end

      private

      def represent(tokens)
        ::GroupAccessTokenSerializer.new.represent(tokens, group: resource)
      end
    end
  end
end
