# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Developer creates tag', :js, feature_category: :source_code_management do
  let(:user) { create(:user) }
  let(:group) { create(:group) }
  let(:project) { create(:project, :repository, namespace: group) }

  before do
    project.add_developer(user)
    sign_in(user)
  end

  context 'from tag list' do
    before do
      visit project_tags_path(project)
      click_link 'New tag'
      wait_for_requests
    end

    it 'with an invalid name displays an error' do
      create_tag_in_form(tag: 'v 1.0', ref: 'master')

      expect(page).to have_content 'Tag name invalid'
    end

    it "doesn't allow to select invalid ref" do
      ref_name = 'foo'
      fill_in 'tag_name', with: 'v2.0'
      ref_selector = '.ref-selector'
      find(ref_selector).click
      wait_for_requests
      page.within(ref_selector) do
        fill_in _('Search by Git revision'), with: ref_name
        wait_for_requests
        expect(find('.gl-dropdown-contents')).not_to have_content(ref_name)
      end
    end

    it 'that already exists displays an error' do
      create_tag_in_form(tag: 'v1.1.0', ref: 'master')

      expect(page).to have_content 'Tag v1.1.0 already exists'
    end

    it 'with multiline message displays the message in a <pre> block' do
      create_tag_in_form(tag: 'v3.0', ref: 'master', message: "Awesome tag message\n\n- hello\n- world")

      expect(page).to have_current_path(
        project_tag_path(project, 'v3.0'), ignore_query: true)
      expect(page).to have_content 'v3.0'
      page.within 'pre.wrap' do
        expect(page).to have_content "Awesome tag message - hello - world"
      end
    end

    it 'opens dropdown for ref' do
      ref_row = find('.form-group:nth-of-type(2) .col-sm-auto')
      page.within ref_row do
        ref_input = find('[name="ref"]', visible: false)
        expect(ref_input.value).to eq 'master'
        expect(find('.gl-dropdown-button-text')).to have_content 'master'
        find('.ref-selector').click
        expect(find('.dropdown-menu')).to have_content 'test'
      end
    end
  end

  def create_tag_in_form(tag:, ref:, message: nil, desc: nil)
    fill_in 'tag_name', with: tag
    select_ref(ref: ref)
    fill_in 'message', with: message unless message.nil?
    fill_in 'release_description', with: desc unless desc.nil?
    click_button 'Create tag'
  end

  def select_ref(ref:)
    ref_selector = '.ref-selector'
    find(ref_selector).click
    wait_for_requests
    page.within(ref_selector) do
      fill_in _('Search by Git revision'), with: ref
      wait_for_requests
      find('li', text: ref, match: :prefer_exact).click
    end
  end
end
