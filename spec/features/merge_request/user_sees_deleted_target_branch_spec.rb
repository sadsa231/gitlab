# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Merge request > User sees deleted target branch', :js, feature_category: :code_review_workflow do
  let(:merge_request) { create(:merge_request) }
  let(:project) { merge_request.project }
  let(:user) { project.creator }

  before do
    project.add_maintainer(user)
    ::Branches::DeleteService.new(project, user).execute('feature')
    sign_in(user)
    visit project_merge_request_path(project, merge_request)
  end

  it 'shows a message about missing target branch' do
    expect(page).to have_content('The target branch feature does not exist')
  end

  it 'does not show link to target branch' do
    expect(page).not_to have_selector('.mr-widget-body .js-branch-text a')
  end
end
