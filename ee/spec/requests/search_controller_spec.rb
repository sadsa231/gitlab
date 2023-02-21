# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SearchController, type: :request, feature_category: :global_search do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }

  let(:project) { create(:project, :public, :repository, :wiki_repo, name: 'awesome project', group: group) }
  let(:projects) { create_list(:project, 5, :public, :repository, :wiki_repo) }

  def send_search_request(params)
    get search_path, params: params
  end

  shared_examples 'an efficient database result' do
    it 'avoids N+1 database queries' do
      create(object, *creation_traits, creation_args)

      ensure_elasticsearch_index!

      control = ActiveRecord::QueryRecorder.new(skip_cached: false) { send_search_request(params) }
      expect(response.body).to include('search-results') # Confirm there are search results to prevent false positives

      projects.each do |project|
        creation_args[:source_project] = project if creation_args.key?(:source_project)
        creation_args[:project] = project if creation_args.key?(:project)
        create(object, *creation_traits, creation_args)
      end

      ensure_elasticsearch_index!

      expect { send_search_request(params) }.not_to exceed_all_query_limit(control).with_threshold(threshold)
      expect(response.body).to include('search-results') # Confirm there are search results to prevent false positives
    end
  end

  describe 'GET /search' do
    context 'when elasticsearch is enabled', :elastic, :sidekiq_inline do
      before do
        stub_ee_application_setting(elasticsearch_search: true, elasticsearch_indexing: true)
        project.add_maintainer(user)

        login_as(user)
      end

      let(:creation_traits) { [] }

      context 'for issues scope' do
        let(:object) { :issue }
        let(:creation_args) { { project: project } }
        let(:params) { { search: '*', scope: 'issues' } }
        # some N+1 queries still exist
        # each issue runs an extra query for project routes
        let(:threshold) { 4 }

        it_behaves_like 'an efficient database result'
      end

      context 'for merge_request scope' do
        let(:creation_traits) { [:unique_branches] }
        let(:object) { :merge_request }
        let(:creation_args) { { source_project: project } }
        let(:params) { { search: '*', scope: 'merge_requests' } }
        # some N+1 queries still exist
        # each merge request runs an extra query for project routes
        let(:threshold) { 4 }

        it_behaves_like 'an efficient database result'
      end

      context 'for project scope' do
        let(:creation_traits) { [:public] }
        let(:object) { :project }
        let(:creation_args) { {} }
        let(:params) { { search: '*', scope: 'projects' } }
        # some N+1 queries still exist
        # each project requires 3 extra queries
        #   - one count for forks
        #   - one count for open MRs
        #   - one count for open Issues
        # there are 4 additional queries run for the logged in user:
        # (1) user preferences, (1) user statuses, (1) user details, (1) users
        # the threshold accounts for 6 projects
        let(:threshold) { 42 }

        it_behaves_like 'an efficient database result'
      end

      context 'for notes scope' do
        let(:creation_traits) { [:on_commit] }
        let(:object) { :note }
        let(:creation_args) { { project: project } }
        let(:params) { { search: '*', scope: 'notes' } }
        # some N+1 still exist
        # each project makes and extra call to get the namespace routes
        let(:threshold) { 6 }

        it_behaves_like 'an efficient database result'
      end

      context 'for milestones scope' do
        let(:object) { :milestone }
        let(:creation_args) { { project: project } }
        let(:params) { { search: '*', scope: 'milestones' } }
        let(:threshold) { 0 }

        it_behaves_like 'an efficient database result'
      end

      context 'for users scope' do
        let(:object) { :user }
        let(:creation_args) { { name: 'georgia' } }
        let(:params) { { search: 'georgia', scope: 'users' } }
        let(:threshold) { 0 }

        it_behaves_like 'an efficient database result'
      end

      context 'for epics scope' do
        let(:object) { :epic }
        let(:creation_args) { { group: group } }
        let(:params) { { group_id: group.id, search: 'title', scope: 'epics' } }
        let(:threshold) { 0 }

        before do
          stub_licensed_features(epics: true)
        end

        it_behaves_like 'an efficient database result'
      end

      context 'for blobs scope' do
        # blobs are enabled for project search only in basic search
        let(:params_for_one) { { search: 'test', project_id: project.id, scope: 'blobs', per_page: 1 } }
        let(:params_for_many) { { search: 'test', project_id: project.id, scope: 'blobs', per_page: 5 } }

        it 'avoids N+1 database queries' do
          project.repository.index_commits_and_blobs
          ensure_elasticsearch_index!

          control = ActiveRecord::QueryRecorder.new { send_search_request(params_for_one) }
          expect(response.body).to include('search-results') # Confirm search results to prevent false positives

          expect { send_search_request(params_for_many) }.not_to exceed_query_limit(control.count)
          expect(response.body).to include('search-results') # Confirm search results to prevent false positives
        end
      end

      context 'for commits scope' do
        let(:params_for_one) { { search: 'test', project_id: project.id, scope: 'commits', per_page: 1 } }
        let(:params_for_many) { { search: 'test', project_id: project.id, scope: 'commits', per_page: 5 } }

        it 'avoids N+1 database queries' do
          project.repository.index_commits_and_blobs
          ensure_elasticsearch_index!

          control = ActiveRecord::QueryRecorder.new { send_search_request(params_for_one) }
          expect(response.body).to include('search-results') # Confirm search results to prevent false positives

          expect { send_search_request(params_for_many) }.not_to exceed_query_limit(control.count)
          expect(response.body).to include('search-results') # Confirm search results to prevent false positives
        end
      end
    end
  end
end
