# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'ProjectCiCdSettingsUpdate', feature_category: :continuous_integration do
  include GraphqlHelpers

  let_it_be(:project) do
    create(:project,
      keep_latest_artifact: true,
      ci_outbound_job_token_scope_enabled: true,
      ci_inbound_job_token_scope_enabled: true
    ).tap(&:save!)
  end

  let(:variables) do
    {
      full_path: project.full_path,
      keep_latest_artifact: false,
      job_token_scope_enabled: false,
      inbound_job_token_scope_enabled: false,
      opt_in_jwt: true
    }
  end

  let(:mutation) { graphql_mutation(:ci_cd_settings_update, variables) }

  context 'when unauthorized' do
    let(:user) { create(:user) }

    shared_examples 'unauthorized' do
      it 'returns an error' do
        post_graphql_mutation(mutation, current_user: user)

        expect(graphql_errors).not_to be_empty
      end
    end

    context 'when not a project member' do
      it_behaves_like 'unauthorized'
    end

    context 'when a non-admin project member' do
      before do
        project.add_developer(user)
      end

      it_behaves_like 'unauthorized'
    end
  end

  context 'when authorized' do
    let_it_be(:user) { project.first_owner }

    it 'updates ci cd settings' do
      post_graphql_mutation(mutation, current_user: user)

      project.reload

      expect(response).to have_gitlab_http_status(:success)
      expect(project.keep_latest_artifact).to eq(false)
    end

    it 'updates job_token_scope_enabled' do
      post_graphql_mutation(mutation, current_user: user)

      project.reload

      expect(response).to have_gitlab_http_status(:success)
      expect(project.ci_outbound_job_token_scope_enabled).to eq(false)
    end

    it 'does not update job_token_scope_enabled if not specified' do
      variables.except!(:job_token_scope_enabled)

      post_graphql_mutation(mutation, current_user: user)

      project.reload

      expect(response).to have_gitlab_http_status(:success)
      expect(project.ci_outbound_job_token_scope_enabled).to eq(true)
    end

    describe 'inbound_job_token_scope_enabled' do
      it 'updates inbound_job_token_scope_enabled' do
        post_graphql_mutation(mutation, current_user: user)

        project.reload

        expect(response).to have_gitlab_http_status(:success)
        expect(project.ci_inbound_job_token_scope_enabled).to eq(false)
      end

      it 'does not update inbound_job_token_scope_enabled if not specified' do
        variables.except!(:inbound_job_token_scope_enabled)

        post_graphql_mutation(mutation, current_user: user)

        project.reload

        expect(response).to have_gitlab_http_status(:success)
        expect(project.ci_inbound_job_token_scope_enabled).to eq(true)
      end

      context 'when ci_inbound_job_token_scope disabled' do
        before do
          stub_feature_flags(ci_inbound_job_token_scope: false)
        end

        it 'does not update inbound_job_token_scope_enabled' do
          post_graphql_mutation(mutation, current_user: user)

          project.reload

          expect(response).to have_gitlab_http_status(:success)
          expect(project.ci_inbound_job_token_scope_enabled).to eq(true)
        end
      end
    end

    it 'updates ci_opt_in_jwt' do
      post_graphql_mutation(mutation, current_user: user)

      project.reload

      expect(response).to have_gitlab_http_status(:success)
      expect(project.ci_opt_in_jwt).to eq(true)
    end

    context 'when bad arguments are provided' do
      let(:variables) { { full_path: '', keep_latest_artifact: false } }

      it 'returns the errors' do
        post_graphql_mutation(mutation, current_user: user)

        expect(graphql_errors).not_to be_empty
      end
    end
  end
end
