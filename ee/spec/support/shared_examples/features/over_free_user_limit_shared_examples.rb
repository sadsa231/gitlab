# frozen_string_literal: true

RSpec.shared_examples_for 'over the free user limit alert' do
  let_it_be(:new_user) { create(:user) }
  let_it_be(:dismiss_button) do
    '[data-testid="user-over-limit-free-plan-dismiss"]'
  end

  before do
    stub_ee_application_setting(dashboard_limit_enabled: true)
  end

  shared_context 'with over storage limit setup' do
    before do
      limit = 100
      group.add_developer(new_user)
      create(:plan_limits, plan: group.gitlab_subscription.hosted_plan, storage_size_limit: limit)
      create(:namespace_root_storage_statistics, namespace: group, storage_size: (limit + 1).megabytes)
    end
  end

  context 'when over limit for notification' do
    before do
      stub_feature_flags(free_user_cap: true)
      stub_feature_flags(preview_free_user_cap: true)
      # setup here so we are over the preview limit, but not the enforcement
      # this will validate we only see one banner
      stub_ee_application_setting(dashboard_notification_limit: 1)
      stub_ee_application_setting(dashboard_enforcement_limit: 3)
    end

    it 'performs dismiss cycle', :js do
      visit_page

      expect(page).not_to have_content('is over the')
      expect(page).not_to have_content('user limit')

      group.add_developer(new_user)

      page.refresh

      expect(page).to have_content('is over the')
      expect(page).to have_content('user limit')

      page.within('[data-testid="user-over-limit-free-plan-alert"]') do
        expect(page).to have_link('Manage members')
        expect(page).to have_link('Explore paid plans')
      end

      find(dismiss_button).click
      wait_for_requests

      page.refresh

      expect(page).not_to have_content('is over the')
      expect(page).not_to have_content('user limit')
    end

    context 'when over storage limits' do
      include_context 'with over storage limit setup'

      it 'does not show alerts' do
        visit_page

        expect(page).to have_content(group.name)
        expect(page).not_to have_content('is over the')
        expect(page).not_to have_content('user limit')
      end
    end
  end

  describe 'with enforcement concerns' do
    before do
      stub_feature_flags(free_user_cap: true)
      stub_feature_flags(preview_free_user_cap: true)
      stub_ee_application_setting(dashboard_enforcement_limit: dashboard_enforcement_limit)
    end

    let(:alert_title_content) do
      'user limit and has been placed in a read-only state'
    end

    context 'when over limit' do
      let(:dashboard_enforcement_limit) { 0 }

      it 'shows free user limit warning', :js do
        visit_page

        expect(page).to have_content(alert_title_content)

        page.within('[data-testid="user-over-limit-free-plan-alert"]') do
          expect(page).to have_link('Manage members')
          expect(page).to have_link('Explore paid plans')
        end

        expect(page).not_to have_css(dismiss_button)
      end

      context 'when over storage limits' do
        include_context 'with over storage limit setup'

        it 'does not show alerts' do
          visit_page

          expect(page).to have_content(group.name)
          expect(page).not_to have_content(alert_title_content)
        end
      end
    end

    context 'when at limit' do
      let(:dashboard_enforcement_limit) { 1 }

      it 'does not show free user limit warning', :js do
        visit_page

        expect(page).to have_content(group.name)
        expect(page).not_to have_content(alert_title_content)
      end
    end

    context 'when under limit' do
      let(:dashboard_enforcement_limit) { 2 }

      it 'does not show free user limit warning', :js do
        visit_page

        expect(page).to have_content(group.name)
        expect(page).not_to have_content(alert_title_content)
      end
    end
  end
end
