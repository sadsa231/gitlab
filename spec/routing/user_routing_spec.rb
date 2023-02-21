# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'user routing', :clean_gitlab_redis_sessions, feature_category: :authentication_and_authorization do
  include SessionHelpers

  context 'when GitHub OAuth on project import is cancelled' do
    it_behaves_like 'redirecting a legacy path', '/users/auth?error=access_denied&state=xyz', '/users/sign_in'
  end

  context 'when GitHub OAuth on sign in is cancelled' do
    before do
      stub_session(auth_on_failure_path: '/projects/new#import_project')
    end

    context 'when all required parameters are present' do
      it_behaves_like 'redirecting a legacy path',
        '/users/auth?error=access_denied&state=xyz',
        '/projects/new#import_project'
    end

    context 'when one of the required parameters is missing' do
      it_behaves_like 'redirecting a legacy path',
        '/users/auth?error=access_denied&state=',
        '/auth'
    end
  end
end
