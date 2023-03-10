# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Projects, '(JavaScript fixtures)', type: :request do
  include ApiHelpers
  include JavaScriptFixturesHelpers

  let(:namespace) { create(:namespace, name: 'gitlab-test') }
  let(:project) { create(:project, :repository, namespace: namespace, path: 'lorem-ipsum') }
  let(:project_empty) { create(:project_empty_repo, namespace: namespace, path: 'lorem-ipsum-empty') }
  let(:user) { project.owner }

  it 'api/projects/get.json' do
    get api("/projects/#{project.id}", user)

    expect(response).to be_successful
  end

  it 'api/projects/get_empty.json' do
    get api("/projects/#{project_empty.id}", user)

    expect(response).to be_successful
  end

  it 'api/projects/branches/get.json' do
    get api("/projects/#{project.id}/repository/branches/#{project.default_branch}", user)

    expect(response).to be_successful
  end
end
