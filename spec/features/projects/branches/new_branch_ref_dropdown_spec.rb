# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'New Branch Ref Dropdown', :js, feature_category: :projects do
  let(:user) { create(:user) }
  let(:project) { create(:project, :public, :repository) }
  let(:sha) { project.commit.sha }
  let(:toggle) { find('.ref-selector') }

  before do
    project.add_maintainer(user)

    sign_in(user)
    visit new_project_branch_path(project)
  end

  it 'finds a tag in a list' do
    tag_name = 'v1.0.0'

    toggle.click

    filter_by(tag_name)

    wait_for_requests

    expect(items_count(tag_name)).to be(1)

    item(tag_name).click

    expect(toggle).to have_content tag_name
  end

  it 'finds a branch in a list' do
    branch_name = 'audio'

    toggle.click

    filter_by(branch_name)

    wait_for_requests

    expect(items_count(branch_name)).to be(1)

    item(branch_name).click

    expect(toggle).to have_content branch_name
  end

  it 'finds a commit in a list' do
    toggle.click

    filter_by(sha)

    wait_for_requests

    sha_short = sha[0, 7]

    expect(items_count(sha_short)).to be(1)

    item(sha_short).click

    expect(toggle).to have_content sha_short
  end

  it 'shows no results when there is no branch, tag or commit sha found' do
    non_existing_ref = 'non_existing_branch_name'

    toggle.click

    filter_by(non_existing_ref)

    wait_for_requests

    expect(find('.gl-dropdown-contents')).not_to have_content(non_existing_ref)
  end

  def item(ref_name)
    find('li', text: ref_name, match: :prefer_exact)
  end

  def items_count(ref_name)
    all('li', text: ref_name, match: :prefer_exact).length
  end

  def filter_by(filter_text)
    fill_in _('Search by Git revision'), with: filter_text
  end
end
