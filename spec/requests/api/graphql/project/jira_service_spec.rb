# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'query Jira service', feature_category: :integrations do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be(:jira_integration) { create(:jira_integration, project: project) }

  let(:query) do
    %(
      query {
        project(fullPath: "#{project.full_path}") {
          services(active: true, type: JIRA_SERVICE) {
            nodes {
              type
              serviceType
            }
          }
        }
      }
    )
  end

  let(:services) { graphql_data.dig('project', 'services', 'nodes') }

  it_behaves_like 'unauthorized users cannot read services'

  context 'when user can access project services' do
    before do
      project.add_maintainer(current_user)
      post_graphql(query, current_user: current_user)
    end

    it_behaves_like 'a working graphql query'

    it 'returns list of jira integrations' do
      expect(services).to contain_exactly({ 'type' => 'JiraService', 'serviceType' => 'JIRA_SERVICE' })
    end
  end
end
