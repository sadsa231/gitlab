# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User activates JetBrains TeamCity CI', feature_category: :integrations do
  include_context 'project integration activation'

  before do
    stub_request(:post, /.*teamcity.example.com.*/)
  end

  it 'activates integration', :js do
    visit_project_integration('JetBrains TeamCity')
    check('Push')
    check('Merge request')
    fill_in('TeamCity server URL', with: 'http://teamcity.example.com')
    fill_in('Build type', with: 'GitlabTest_Build')
    fill_in('Username', with: 'user')
    fill_in('Password', with: 'verySecret')

    click_test_then_save_integration(expect_test_to_fail: false)

    expect(page).to have_content('JetBrains TeamCity settings saved and active.')
  end
end
