# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Merge request > User marks merge request as draft', :js, feature_category: :code_review_workflow do
  let(:user) { create(:user) }
  let(:project) { create(:project, :public, :repository) }
  let(:merge_request) { create(:merge_request, source_project: project) }

  before do
    project.add_maintainer(user)

    sign_in(user)

    visit project_merge_request_path(project, merge_request)
  end

  it 'toggles draft status' do
    find('[data-testid="merge-request-actions"]').click
    click_link 'Mark as draft'

    expect(page).to have_content("Draft: #{merge_request.title}")

    find('[data-testid="merge-request-actions"]').click

    page.within('.detail-page-header-actions') do
      click_link 'Mark as ready'
    end

    expect(page).to have_content(merge_request.title)
  end
end
