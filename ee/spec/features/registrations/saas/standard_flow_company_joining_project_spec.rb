# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Standard flow for user picking company and joining a project', :js, :saas, :saas_registration,
feature_category: :onboarding do
  it 'registers the user and sends them to a project listing page' do
    user_signs_up

    expect_to_see_account_confirmation_page

    confirm_account

    user_signs_in

    expect_to_see_welcome_form

    fills_in_welcome_form
    click_on 'Continue'

    expect_to_be_on_projects_dashboard_with_zero_authorized_projects
  end

  def user_signs_up
    new_user = build(:user, name: 'Registering User', email: user_email)

    visit new_user_registration_path

    fill_in 'First name', with: new_user.first_name
    fill_in 'Last name', with: new_user.last_name
    fill_in 'Username', with: new_user.username
    fill_in 'Email', with: new_user.email
    fill_in 'Password', with: new_user.password

    wait_for_all_requests

    click_button 'Register'
  end

  def fills_in_welcome_form
    select 'Software Developer', from: 'user_role'
    select 'A different reason', from: 'user_registration_objective'
    fill_in 'Why are you signing up? (optional)', with: 'My reason'

    choose 'My company or team'
    choose 'Join a project'
  end

  def expect_to_see_welcome_form
    expect(page).to have_content('Welcome to GitLab, Registering!')

    page.within(welcome_form_selector) do
      expect(page).to have_content('Role')
      expect(page).to have_field('user_role', valid: false)
      expect(page).to have_field('user_setup_for_company_true', valid: false)
      expect(page).to have_content('I\'m signing up for GitLab because:')
      expect(page).to have_content('Who will be using GitLab?')
      expect(page).to have_content('What would you like to do?')
      expect(page).not_to have_content('I\'d like to receive updates about GitLab via email')
    end
  end
end
