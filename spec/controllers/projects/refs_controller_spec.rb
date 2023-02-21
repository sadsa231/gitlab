# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::RefsController, feature_category: :source_code_management do
  let_it_be(:project) { create(:project, :repository) }
  let(:user) { create(:user) }

  before do
    sign_in(user)
    project.add_developer(user)
  end

  describe 'GET #switch' do
    using RSpec::Parameterized::TableSyntax

    let(:id) { 'master' }
    let(:params) do
      { destination: destination, namespace_id: project.namespace.to_param, project_id: project, id: id,
        ref_type: ref_type }
    end

    subject { get :switch, params: params }

    context 'when the use_ref_type_parameter feature flag is not enabled' do
      before do
        stub_feature_flags(use_ref_type_parameter: false)
      end

      where(:destination, :ref_type, :redirected_to) do
        'tree'           | nil     | lazy { project_tree_path(project, id) }
        'tree'           | 'heads' | lazy { project_tree_path(project, id) }
        'blob'           | nil     | lazy { project_blob_path(project, id) }
        'blob'           | 'heads' | lazy { project_blob_path(project, id) }
        'graph'          | nil     | lazy { project_network_path(project, id) }
        'graph'          | 'heads' | lazy { project_network_path(project, id) }
        'graphs'         | nil     | lazy { project_graph_path(project, id) }
        'graphs'         | 'heads' | lazy { project_graph_path(project, id) }
        'find_file'      | nil     | lazy { project_find_file_path(project, id) }
        'find_file'      | 'heads' | lazy { project_find_file_path(project, id) }
        'graphs_commits' | nil     | lazy { commits_project_graph_path(project, id) }
        'graphs_commits' | 'heads' | lazy { commits_project_graph_path(project, id) }
        'badges'         | nil     | lazy { project_settings_ci_cd_path(project, ref: id) }
        'badges'         | 'heads' | lazy { project_settings_ci_cd_path(project, ref: id) }
        'commits'        | nil     | lazy { project_commits_path(project, id) }
        'commits'        | 'heads' | lazy { project_commits_path(project, id) }
        'somethingelse'  | nil     | lazy { project_commits_path(project, id) }
        'somethingelse'  | 'heads' | lazy { project_commits_path(project, id) }
      end

      with_them do
        it 'redirects to destination' do
          expect(subject).to redirect_to(redirected_to)
        end
      end
    end

    context 'when the use_ref_type_parameter feature flag is enabled' do
      where(:destination, :ref_type, :redirected_to) do
        'tree'           | nil     | lazy { project_tree_path(project, id) }
        'tree'           | 'heads' | lazy { project_tree_path(project, id) }
        'blob'           | nil     | lazy { project_blob_path(project, id) }
        'blob'           | 'heads' | lazy { project_blob_path(project, id) }
        'graph'          | nil     | lazy { project_network_path(project, id) }
        'graph'          | 'heads' | lazy { project_network_path(project, id, ref_type: 'heads') }
        'graphs'         | nil     | lazy { project_graph_path(project, id) }
        'graphs'         | 'heads' | lazy { project_graph_path(project, id, ref_type: 'heads') }
        'find_file'      | nil     | lazy { project_find_file_path(project, id) }
        'find_file'      | 'heads' | lazy { project_find_file_path(project, id) }
        'graphs_commits' | nil     | lazy { commits_project_graph_path(project, id) }
        'graphs_commits' | 'heads' | lazy { commits_project_graph_path(project, id) }
        'badges'         | nil     | lazy { project_settings_ci_cd_path(project, ref: id) }
        'badges'         | 'heads' | lazy { project_settings_ci_cd_path(project, ref: id) }
        'commits'        | nil     | lazy { project_commits_path(project, id) }
        'commits'        | 'heads' | lazy { project_commits_path(project, id, ref_type: 'heads') }
        nil              | nil     | lazy { project_commits_path(project, id) }
        nil              | 'heads' | lazy { project_commits_path(project, id, ref_type: 'heads') }
      end

      with_them do
        it 'redirects to destination' do
          expect(subject).to redirect_to(redirected_to)
        end
      end
    end
  end

  describe 'GET #logs_tree' do
    let(:path) { 'foo/bar/baz.html' }

    def default_get(format = :html)
      get :logs_tree,
          params: {
            namespace_id: project.namespace.to_param,
            project_id: project,
            id: 'master',
            path: path
          },
          format: format
    end

    def xhr_get(format = :html, params = {})
      get :logs_tree, params: {
        namespace_id: project.namespace.to_param,
        project_id: project,
        id: 'master',
        path: path,
        format: format
      }.merge(params), xhr: true
    end

    it 'never throws MissingTemplate' do
      expect { default_get }.not_to raise_error
      expect { xhr_get(:json) }.not_to raise_error
      expect { xhr_get }.not_to raise_error
    end

    it 'renders 404 for HTML requests' do
      xhr_get

      expect(response).to be_not_found
    end

    context 'when ref is incorrect' do
      it 'returns 404 page' do
        xhr_get(:json, id: '.')

        expect(response).to be_not_found
      end
    end

    context 'when offset has an invalid format' do
      it 'renders JSON' do
        xhr_get(:json, offset: { wrong: :format })

        expect(response).to be_successful
        expect(json_response).to be_kind_of(Array)
      end
    end

    context 'when json is requested' do
      it 'renders JSON' do
        expect(::Gitlab::GitalyClient).to receive(:allow_ref_name_caching).and_call_original

        xhr_get(:json)

        expect(response).to be_successful
        expect(json_response).to be_kind_of(Array)
      end
    end
  end
end
