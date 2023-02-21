# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Sentry', feature_category: :error_tracking do
  context 'when enable_new_sentry_clientside_integration is disabled' do
    before do
      stub_feature_flags(enable_new_sentry_clientside_integration: false)
    end

    it 'does not load sentry if sentry is disabled' do
      allow(Gitlab.config.sentry).to receive(:enabled).and_return(false)

      visit new_user_session_path

      expect(has_requested_legacy_sentry).to eq(false)
    end

    it 'loads legacy sentry if sentry config is enabled', :js do
      allow(Gitlab.config.sentry).to receive(:enabled).and_return(true)

      visit new_user_session_path

      expect(has_requested_legacy_sentry).to eq(true)
      expect(evaluate_script('window._Sentry.SDK_VERSION')).to match(%r{^5\.})
    end
  end

  context 'when enable_new_sentry_clientside_integration is enabled' do
    before do
      stub_feature_flags(enable_new_sentry_clientside_integration: true)
    end

    it 'does not load sentry if sentry settings are disabled' do
      allow(Gitlab::CurrentSettings).to receive(:sentry_enabled).and_return(false)

      visit new_user_session_path

      expect(has_requested_sentry).to eq(false)
    end

    it 'loads sentry if sentry settings are enabled', :js do
      allow(Gitlab::CurrentSettings).to receive(:sentry_enabled).and_return(true)

      visit new_user_session_path

      expect(has_requested_sentry).to eq(true)
      expect(evaluate_script('window._Sentry.SDK_VERSION')).to match(%r{^7\.})
    end
  end

  def has_requested_legacy_sentry
    page.all('script', visible: false).one? do |elm|
      elm[:src] =~ %r{/legacy_sentry.*\.chunk\.js\z}
    end
  end

  def has_requested_sentry
    page.all('script', visible: false).one? do |elm|
      elm[:src] =~ %r{/sentry.*\.chunk\.js\z}
    end
  end
end
