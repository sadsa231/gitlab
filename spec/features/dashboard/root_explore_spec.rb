# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Root explore', feature_category: :not_owned do
  let_it_be(:public_project) { create(:project, :public) }
  let_it_be(:archived_project) { create(:project, :archived) }
  let_it_be(:internal_project) { create(:project, :internal) }
  let_it_be(:private_project) { create(:project, :private) }

  before do
    allow(Gitlab).to receive(:com?).and_return(true)
  end

  context 'when logged in' do
    let_it_be(:user) { create(:user) }

    before do
      sign_in(user)
      visit explore_projects_path
    end

    include_examples 'shows public and internal projects'
  end

  context 'when not logged in' do
    before do
      visit explore_projects_path
    end

    include_examples 'shows public projects'
  end

  describe 'project language dropdown' do
    let(:has_language_dropdown?) { page.has_selector?('[data-testid="project-language-dropdown"]') }

    it 'is conditionally rendered' do
      visit explore_projects_path

      expect(has_language_dropdown?).to eq(true)
    end

    context 'with project_language_search ff disabled' do
      before do
        stub_feature_flags(project_language_search: false)
      end

      it 'is conditionally rendered' do
        visit explore_projects_path

        expect(has_language_dropdown?).to eq(false)
      end
    end
  end
end
