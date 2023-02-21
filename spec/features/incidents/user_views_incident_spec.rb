# frozen_string_literal: true

require "spec_helper"

RSpec.describe "User views incident", feature_category: :incident_management do
  let_it_be(:project) { create(:project_empty_repo, :public) }
  let_it_be(:guest) { create(:user) }
  let_it_be(:developer) { create(:user) }
  let_it_be(:user) { developer }
  let(:author) { developer }
  let(:description) { "# Description header\n\n**Lorem** _ipsum_ dolor sit [amet](https://example.com)" }
  let(:incident) { create(:incident, project: project, description: description, author: author) }

  before_all do
    project.add_developer(developer)
    project.add_guest(guest)
  end

  before do
    sign_in(user)

    visit(incident_project_issues_path(project, incident))
  end

  specify do
    expect(page).to have_header_with_correct_id_and_link(1, 'Description header', 'description-header')
  end

  it_behaves_like 'page meta description', ' Description header Lorem ipsum dolor sit amet'

  describe 'user actions' do
    it 'shows the merge request and incident actions', :js, :aggregate_failures do
      expected_href = new_project_issue_path(project,
                                             issuable_template: 'incident',
                                             issue: { issue_type: 'incident' },
                                             add_related_issue: incident.iid)

      click_button 'Incident actions'

      expect(page).to have_link('New related incident', href: expected_href)
      expect(page).to have_button('Create merge request')
      expect(page).to have_button('Close incident')
    end

    context 'when user is guest' do
      let(:user) { guest }

      context 'and author' do
        let(:author) { guest }

        it 'does not show the incident actions', :js do
          expect(page).not_to have_button('Incident actions')
        end
      end

      context 'and not author' do
        it 'shows incident actions', :js do
          click_button 'Incident actions'

          expect(page).to have_button 'Report abuse to administrator'
        end
      end
    end
  end

  context 'when the project is archived' do
    before_all do
      project.update!(archived: true)
    end

    it 'does not show the incident actions', :js do
      expect(page).not_to have_button('Incident actions')
    end
  end

  describe 'user status' do
    context 'when showing status of the author of the incident' do
      subject { visit(incident_project_issues_path(project, incident)) }

      it_behaves_like 'showing user status' do
        let(:user_with_status) { user }
      end
    end

    context 'when status message has an emoji', :js do
      let_it_be(:message) { 'My status with an emoji' }
      let_it_be(:message_emoji) { 'basketball' }
      let_it_be(:status) { create(:user_status, user: user, emoji: 'smirk', message: "#{message} :#{message_emoji}:") }

      it 'correctly renders the emoji' do
        wait_for_requests

        tooltip_span = page.first(".user-status-emoji[title^='#{message}']")
        tooltip_span.hover

        wait_for_requests

        tooltip = page.find('.tooltip .tooltip-inner')

        page.within(tooltip) do
          expect(page).to have_emoji(message_emoji)
        end
      end
    end
  end
end
