# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Query.runner(id)', feature_category: :runner_fleet do
  include GraphqlHelpers

  let_it_be(:user) { create(:user, :admin) }
  let_it_be(:group) { create(:group) }

  let_it_be(:active_instance_runner) do
    create(:ci_runner, :instance,
      description: 'Runner 1',
      contacted_at: 2.hours.ago,
      active: true,
      version: 'adfe156',
      revision: 'a',
      locked: true,
      ip_address: '127.0.0.1',
      maximum_timeout: 600,
      access_level: 0,
      tag_list: %w[tag1 tag2],
      run_untagged: true,
      executor_type: :custom,
      maintenance_note: '**Test maintenance note**')
  end

  let_it_be(:inactive_instance_runner) do
    create(:ci_runner, :instance,
      description: 'Runner 2',
      contacted_at: 1.day.ago,
      active: false,
      version: 'adfe157',
      revision: 'b',
      ip_address: '10.10.10.10',
      access_level: 1,
      run_untagged: true)
  end

  let_it_be(:active_group_runner) do
    create(:ci_runner, :group,
      groups: [group],
      description: 'Group runner 1',
      contacted_at: 2.hours.ago,
      active: true,
      version: 'adfe156',
      revision: 'a',
      locked: true,
      ip_address: '127.0.0.1',
      maximum_timeout: 600,
      access_level: 0,
      tag_list: %w[tag1 tag2],
      run_untagged: true,
      executor_type: :shell)
  end

  let_it_be(:project1) { create(:project) }
  let_it_be(:active_project_runner) { create(:ci_runner, :project, projects: [project1]) }

  shared_examples 'runner details fetch' do
    let(:query) do
      wrap_fields(query_graphql_path(query_path, all_graphql_fields_for('CiRunner')))
    end

    let(:query_path) do
      [
        [:runner, { id: runner.to_global_id.to_s }]
      ]
    end

    it 'retrieves expected fields' do
      post_graphql(query, current_user: user)

      runner_data = graphql_data_at(:runner)
      expect(runner_data).not_to be_nil

      expect(runner_data).to match a_graphql_entity_for(
        runner,
        description: runner.description,
        created_at: runner.created_at&.iso8601,
        contacted_at: runner.contacted_at&.iso8601,
        version: runner.version,
        short_sha: runner.short_sha,
        revision: runner.revision,
        locked: false,
        active: runner.active,
        paused: !runner.active,
        status: runner.status('14.5').to_s.upcase,
        job_execution_status: runner.builds.running.any? ? 'RUNNING' : 'IDLE',
        maximum_timeout: runner.maximum_timeout,
        access_level: runner.access_level.to_s.upcase,
        run_untagged: runner.run_untagged,
        ip_address: runner.ip_address,
        runner_type: runner.instance_type? ? 'INSTANCE_TYPE' : 'PROJECT_TYPE',
        executor_name: runner.executor_type&.dasherize,
        architecture_name: runner.architecture,
        platform_name: runner.platform,
        maintenance_note: runner.maintenance_note,
        maintenance_note_html:
          runner.maintainer_note.present? ? a_string_including('<strong>Test maintenance note</strong>') : '',
        job_count: runner.builds.count,
        jobs: a_hash_including(
          "count" => runner.builds.count,
          "nodes" => an_instance_of(Array),
          "pageInfo" => anything
        ),
        project_count: nil,
        admin_url: "http://localhost/admin/runners/#{runner.id}",
        user_permissions: {
          'readRunner' => true,
          'updateRunner' => true,
          'deleteRunner' => true,
          'assignRunner' => true
        }
      )
      expect(runner_data['tagList']).to match_array runner.tag_list
    end
  end

  shared_examples 'retrieval with no admin url' do
    let(:query) do
      wrap_fields(query_graphql_path(query_path, all_graphql_fields_for('CiRunner')))
    end

    let(:query_path) do
      [
        [:runner, { id: runner.to_global_id.to_s }]
      ]
    end

    it 'retrieves expected fields' do
      post_graphql(query, current_user: user)

      runner_data = graphql_data_at(:runner)
      expect(runner_data).not_to be_nil

      expect(runner_data).to match a_graphql_entity_for(runner, admin_url: nil)
      expect(runner_data['tagList']).to match_array runner.tag_list
    end
  end

  shared_examples 'retrieval by unauthorized user' do
    let(:query) do
      wrap_fields(query_graphql_path(query_path, all_graphql_fields_for('CiRunner')))
    end

    let(:query_path) do
      [
        [:runner, { id: runner.to_global_id.to_s }]
      ]
    end

    it 'returns null runner' do
      post_graphql(query, current_user: user)

      expect(graphql_data_at(:runner)).to be_nil
    end
  end

  describe 'for active runner' do
    let(:runner) { active_instance_runner }

    it_behaves_like 'runner details fetch'

    context 'when tagList is not requested' do
      let(:query) do
        wrap_fields(query_graphql_path(query_path, 'id'))
      end

      let(:query_path) do
        [
          [:runner, { id: runner.to_global_id.to_s }]
        ]
      end

      it 'does not retrieve tagList' do
        post_graphql(query, current_user: user)

        runner_data = graphql_data_at(:runner)
        expect(runner_data).not_to be_nil
        expect(runner_data).not_to include('tagList')
      end
    end

    context 'with build running' do
      before do
        project = create(:project, :repository)
        pipeline = create(:ci_pipeline, project: project)
        create(:ci_build, :running, runner: runner, pipeline: pipeline)
      end

      it_behaves_like 'runner details fetch'
    end
  end

  describe 'for project runner' do
    describe 'locked' do
      using RSpec::Parameterized::TableSyntax

      where(is_locked: [true, false])

      with_them do
        let(:project_runner) do
          create(:ci_runner, :project,
            description: 'Runner 3',
            contacted_at: 1.day.ago,
            active: false,
            locked: is_locked,
            version: 'adfe157',
            revision: 'b',
            ip_address: '10.10.10.10',
            access_level: 1,
            run_untagged: true)
        end

        let(:query) do
          wrap_fields(query_graphql_path(query_path, 'id locked'))
        end

        let(:query_path) do
          [
            [:runner, { id: project_runner.to_global_id.to_s }]
          ]
        end

        it 'retrieves correct locked value' do
          post_graphql(query, current_user: user)

          runner_data = graphql_data_at(:runner)

          expect(runner_data).to match a_graphql_entity_for(project_runner, locked: is_locked)
        end
      end
    end

    describe 'jobCount' do
      let_it_be(:pipeline1) { create(:ci_pipeline, project: project1) }
      let_it_be(:pipeline2) { create(:ci_pipeline, project: project1) }
      let_it_be(:build1) { create(:ci_build, :running, runner: active_project_runner, pipeline: pipeline1) }
      let_it_be(:build2) { create(:ci_build, :running, runner: active_project_runner, pipeline: pipeline2) }

      let(:runner_query_fragment) { 'id jobCount' }
      let(:query) do
        %(
          query {
            runner1: runner(id: "#{active_project_runner.to_global_id}") { #{runner_query_fragment} }
            runner2: runner(id: "#{inactive_instance_runner.to_global_id}") { #{runner_query_fragment} }
          }
        )
      end

      it 'retrieves correct jobCount values' do
        post_graphql(query, current_user: user)

        expect(graphql_data).to match a_hash_including(
          'runner1' => a_graphql_entity_for(active_project_runner, job_count: 2),
          'runner2' => a_graphql_entity_for(inactive_instance_runner, job_count: 0)
        )
      end

      context 'when JOB_COUNT_LIMIT is in effect' do
        before do
          stub_const('Types::Ci::RunnerType::JOB_COUNT_LIMIT', 0)
        end

        it 'retrieves correct capped jobCount values' do
          post_graphql(query, current_user: user)

          expect(graphql_data).to match a_hash_including(
            'runner1' => a_graphql_entity_for(active_project_runner, job_count: 1),
            'runner2' => a_graphql_entity_for(inactive_instance_runner, job_count: 0)
          )
        end
      end
    end

    describe 'ownerProject' do
      let_it_be(:project2) { create(:project) }
      let_it_be(:runner1) { create(:ci_runner, :project, projects: [project2, project1]) }
      let_it_be(:runner2) { create(:ci_runner, :project, projects: [project1, project2]) }

      let(:runner_query_fragment) { 'id ownerProject { id }' }
      let(:query) do
        %(
          query {
            runner1: runner(id: "#{runner1.to_global_id}") { #{runner_query_fragment} }
            runner2: runner(id: "#{runner2.to_global_id}") { #{runner_query_fragment} }
          }
        )
      end

      it 'retrieves correct ownerProject.id values' do
        post_graphql(query, current_user: user)

        expect(graphql_data).to match a_hash_including(
          'runner1' => a_graphql_entity_for(runner1, owner_project: a_graphql_entity_for(project2)),
          'runner2' => a_graphql_entity_for(runner2, owner_project: a_graphql_entity_for(project1))
        )
      end
    end
  end

  describe 'for inactive runner' do
    let(:runner) { inactive_instance_runner }

    it_behaves_like 'runner details fetch'
  end

  describe 'for group runner request' do
    let(:query) do
      %(
        query {
          runner(id: "#{active_group_runner.to_global_id}") {
            groups {
              nodes {
                id
              }
            }
          }
        }
      )
    end

    it 'retrieves groups field with expected value' do
      post_graphql(query, current_user: user)

      runner_data = graphql_data_at(:runner, :groups, :nodes)
      expect(runner_data).to contain_exactly(a_graphql_entity_for(group))
    end
  end

  describe 'for runner with status' do
    let_it_be(:stale_runner) { create(:ci_runner, description: 'Stale runner 1', created_at: 3.months.ago) }
    let_it_be(:never_contacted_instance_runner) { create(:ci_runner, description: 'Missing runner 1', created_at: 1.month.ago, contacted_at: nil) }

    let(:status_fragment) do
      %(
        status
        legacyStatusWithExplicitVersion: status(legacyMode: "14.5")
        newStatus: status(legacyMode: null)
      )
    end

    let(:query) do
      %(
        query {
          staleRunner: runner(id: "#{stale_runner.to_global_id}") { #{status_fragment} }
          pausedRunner: runner(id: "#{inactive_instance_runner.to_global_id}") { #{status_fragment} }
          neverContactedInstanceRunner: runner(id: "#{never_contacted_instance_runner.to_global_id}") { #{status_fragment} }
        }
      )
    end

    it 'retrieves status fields with expected values' do
      post_graphql(query, current_user: user)

      stale_runner_data = graphql_data_at(:stale_runner)
      expect(stale_runner_data).to match a_hash_including(
        'status' => 'STALE',
        'legacyStatusWithExplicitVersion' => 'STALE',
        'newStatus' => 'STALE'
      )

      paused_runner_data = graphql_data_at(:paused_runner)
      expect(paused_runner_data).to match a_hash_including(
        'status' => 'PAUSED',
        'legacyStatusWithExplicitVersion' => 'PAUSED',
        'newStatus' => 'OFFLINE'
      )

      never_contacted_instance_runner_data = graphql_data_at(:never_contacted_instance_runner)
      expect(never_contacted_instance_runner_data).to match a_hash_including(
        'status' => 'NEVER_CONTACTED',
        'legacyStatusWithExplicitVersion' => 'NEVER_CONTACTED',
        'newStatus' => 'NEVER_CONTACTED'
      )
    end
  end

  describe 'for multiple runners' do
    let_it_be(:project2) { create(:project, :test_repo) }
    let_it_be(:project_runner1) { create(:ci_runner, :project, projects: [project1, project2], description: 'Runner 1') }
    let_it_be(:project_runner2) { create(:ci_runner, :project, projects: [], description: 'Runner 2') }

    let!(:job) { create(:ci_build, runner: project_runner1) }

    context 'requesting projects and counts for projects and jobs' do
      let(:jobs_fragment) do
        %(
          jobs {
            count
            nodes {
              id
              status
            }
          }
        )
      end

      let(:query) do
        %(
          query {
            projectRunner1: runner(id: "#{project_runner1.to_global_id}") {
              projectCount
              jobCount
              #{jobs_fragment}
              projects {
                nodes {
                  id
                }
              }
            }
            projectRunner2: runner(id: "#{project_runner2.to_global_id}") {
              projectCount
              jobCount
              #{jobs_fragment}
              projects {
                nodes {
                  id
                }
              }
            }
            activeInstanceRunner: runner(id: "#{active_instance_runner.to_global_id}") {
              projectCount
              jobCount
              #{jobs_fragment}
              projects {
                nodes {
                  id
                }
              }
            }
          }
        )
      end

      before do
        project_runner2.runner_projects.clear

        post_graphql(query, current_user: user)
      end

      it 'retrieves expected fields' do
        runner1_data = graphql_data_at(:project_runner1)
        runner2_data = graphql_data_at(:project_runner2)
        runner3_data = graphql_data_at(:active_instance_runner)

        expect(runner1_data).to match a_hash_including(
          'jobCount' => 1,
          'jobs' => a_hash_including(
            "count" => 1,
            "nodes" => [a_graphql_entity_for(job, status: job.status.upcase)]
          ),
          'projectCount' => 2,
          'projects' => {
            'nodes' => [
              a_graphql_entity_for(project1),
              a_graphql_entity_for(project2)
            ]
          })
        expect(runner2_data).to match a_hash_including(
          'jobCount' => 0,
          'jobs' => nil, # returning jobs not allowed for more than 1 runner (see RunnerJobsResolver)
          'projectCount' => 0,
          'projects' => {
            'nodes' => []
          })
        expect(runner3_data).to match a_hash_including(
          'jobCount' => 0,
          'jobs' => nil, # returning jobs not allowed for more than 1 runner (see RunnerJobsResolver)
          'projectCount' => nil,
          'projects' => nil)

        expect_graphql_errors_to_include [/"jobs" field can be requested only for 1 CiRunner\(s\) at a time./]
      end
    end
  end

  describe 'by regular user' do
    let(:user) { create(:user) }

    context 'on instance runner' do
      let(:runner) { active_instance_runner }

      it_behaves_like 'retrieval by unauthorized user'
    end

    context 'on group runner' do
      let(:runner) { active_group_runner }

      it_behaves_like 'retrieval by unauthorized user'
    end

    context 'on project runner' do
      let(:runner) { active_project_runner }

      it_behaves_like 'retrieval by unauthorized user'
    end
  end

  describe 'by non-admin user' do
    let(:user) { create(:user) }

    before do
      group.add_member(user, Gitlab::Access::OWNER)
    end

    it_behaves_like 'retrieval with no admin url' do
      let(:runner) { active_group_runner }
    end
  end

  describe 'by unauthenticated user' do
    let(:user) { nil }

    it_behaves_like 'retrieval by unauthorized user' do
      let(:runner) { active_instance_runner }
    end
  end

  describe 'Query limits' do
    def runner_query(runner)
      <<~SINGLE
        runner(id: "#{runner.to_global_id}") {
          #{all_graphql_fields_for('CiRunner', excluded: excluded_fields)}
          groups {
            nodes {
              id
              path
              fullPath
              webUrl
            }
          }
          projects {
            nodes {
              id
              path
              fullPath
              webUrl
            }
          }
          ownerProject {
            id
            path
            fullPath
            webUrl
          }
        }
      SINGLE
    end

    let(:active_project_runner2) { create(:ci_runner, :project) }
    let(:active_group_runner2) { create(:ci_runner, :group) }

    # Exclude fields that are already hardcoded above
    let(:excluded_fields) { %w[jobs groups projects ownerProject] }

    let(:single_query) do
      <<~QUERY
        {
          instance_runner1: #{runner_query(active_instance_runner)}
          group_runner1: #{runner_query(active_group_runner)}
          project_runner1: #{runner_query(active_project_runner)}
        }
      QUERY
    end

    let(:double_query) do
      <<~QUERY
        {
          instance_runner1: #{runner_query(active_instance_runner)}
          instance_runner2: #{runner_query(inactive_instance_runner)}
          group_runner1: #{runner_query(active_group_runner)}
          group_runner2: #{runner_query(active_group_runner2)}
          project_runner1: #{runner_query(active_project_runner)}
          project_runner2: #{runner_query(active_project_runner2)}
        }
      QUERY
    end

    it 'does not execute more queries per runner', :aggregate_failures do
      # warm-up license cache and so on:
      personal_access_token = create(:personal_access_token, user: user)
      args = { current_user: user, token: { personal_access_token: personal_access_token } }
      post_graphql(double_query, **args)

      control = ActiveRecord::QueryRecorder.new { post_graphql(single_query, **args) }

      expect { post_graphql(double_query, **args) }.not_to exceed_query_limit(control)

      expect(graphql_data.count).to eq 6
      expect(graphql_data).to match(
        a_hash_including(
          'instance_runner1' => a_graphql_entity_for(active_instance_runner),
          'instance_runner2' => a_graphql_entity_for(inactive_instance_runner),
          'group_runner1' => a_graphql_entity_for(
            active_group_runner,
            groups: { 'nodes' => contain_exactly(a_graphql_entity_for(group)) }
          ),
          'group_runner2' => a_graphql_entity_for(
            active_group_runner2,
            groups: { 'nodes' => active_group_runner2.groups.map { |g| a_graphql_entity_for(g) } }
          ),
          'project_runner1' => a_graphql_entity_for(
            active_project_runner,
            projects: { 'nodes' => active_project_runner.projects.map { |p| a_graphql_entity_for(p) } },
            owner_project: a_graphql_entity_for(active_project_runner.projects[0])
          ),
          'project_runner2' => a_graphql_entity_for(
            active_project_runner2,
            projects: { 'nodes' => active_project_runner2.projects.map { |p| a_graphql_entity_for(p) } },
            owner_project: a_graphql_entity_for(active_project_runner2.projects[0])
          )
        ))
    end
  end

  describe 'Query limits with jobs' do
    let!(:group1) { create(:group) }
    let!(:group2) { create(:group) }
    let!(:project1) { create(:project, :repository, group: group1) }
    let!(:project2) { create(:project, :repository, group: group1) }
    let!(:project3) { create(:project, :repository, group: group2) }

    let!(:merge_request1) { create(:merge_request, source_project: project1) }
    let!(:merge_request2) { create(:merge_request, source_project: project3) }

    let(:project_runner2) { create(:ci_runner, :project, projects: [project1, project2]) }
    let!(:build1) { create(:ci_build, :success, name: 'Build One', runner: project_runner2, pipeline: pipeline1) }
    let!(:pipeline1) do
      create(:ci_pipeline, project: project1, source: :merge_request_event, merge_request: merge_request1, ref: 'main',
                           target_sha: 'xxx')
    end

    let(:query) do
      <<~QUERY
        {
          runner(id: "#{project_runner2.to_global_id}") {
            id
            jobs {
              nodes {
                id
                detailedStatus {
                  id
                  detailsPath
                  group
                  icon
                  text
                }
                project {
                  id
                  name
                  webUrl
                }
                shortSha
                commitPath
                finishedAt
                duration
                queuedDuration
                tags
              }
            }
          }
        }
      QUERY
    end

    it 'does not execute more queries per job', :aggregate_failures do
      # warm-up license cache and so on:
      personal_access_token = create(:personal_access_token, user: user)
      args = { current_user: user, token: { personal_access_token: personal_access_token } }
      post_graphql(query, **args)

      control = ActiveRecord::QueryRecorder.new(query_recorder_debug: true) { post_graphql(query, **args) }

      # Add a new build to project_runner2
      project_runner2.runner_projects << build(:ci_runner_project, runner: project_runner2, project: project3)
      pipeline2 = create(:ci_pipeline, project: project3, source: :merge_request_event, merge_request: merge_request2,
                                       ref: 'main', target_sha: 'xxx')
      build2 = create(:ci_build, :success, name: 'Build Two', runner: project_runner2, pipeline: pipeline2)

      args[:current_user] = create(:user, :admin) # do not reuse same user
      expect { post_graphql(query, **args) }.not_to exceed_all_query_limit(control)

      expect(graphql_data.count).to eq 1
      expect(graphql_data).to match(
        a_hash_including(
          'runner' => a_graphql_entity_for(
            project_runner2,
            jobs: { 'nodes' => containing_exactly(a_graphql_entity_for(build1), a_graphql_entity_for(build2)) }
          )
        ))
    end
  end

  describe 'sorting and pagination' do
    let(:query) do
      <<~GQL
      query($id: CiRunnerID!, $projectSearchTerm: String, $n: Int, $cursor: String) {
        runner(id: $id) {
          #{fields}
        }
      }
      GQL
    end

    before do
      post_graphql(query, current_user: user, variables: variables)
    end

    context 'with project search term' do
      let_it_be(:project1) { create(:project, description: 'abc') }
      let_it_be(:project2) { create(:project, description: 'def') }
      let_it_be(:project_runner) do
        create(:ci_runner, :project, projects: [project1, project2])
      end

      let(:variables) { { id: project_runner.to_global_id.to_s, n: n, project_search_term: search_term } }

      let(:fields) do
        <<~QUERY
        projects(search: $projectSearchTerm, first: $n, after: $cursor) {
          count
          nodes {
            id
          }
          pageInfo {
            hasPreviousPage
            startCursor
            endCursor
            hasNextPage
          }
        }
        QUERY
      end

      let(:projects_data) { graphql_data_at('runner', 'projects') }

      context 'set to empty string' do
        let(:search_term) { '' }

        context 'with n = 1' do
          let(:n) { 1 }

          it_behaves_like 'a working graphql query'

          it 'returns paged result' do
            expect(projects_data).not_to be_nil
            expect(projects_data['count']).to eq 2
            expect(projects_data['pageInfo']['hasNextPage']).to eq true
          end
        end

        context 'with n = 2' do
          let(:n) { 2 }

          it 'returns non-paged result' do
            expect(projects_data).not_to be_nil
            expect(projects_data['count']).to eq 2
            expect(projects_data['pageInfo']['hasNextPage']).to eq false
          end
        end
      end

      context 'set to partial match' do
        let(:search_term) { 'def' }

        context 'with n = 1' do
          let(:n) { 1 }

          it_behaves_like 'a working graphql query'

          it 'returns paged result with no additional pages' do
            expect(projects_data).not_to be_nil
            expect(projects_data['count']).to eq 1
            expect(projects_data['pageInfo']['hasNextPage']).to eq false
          end
        end
      end
    end
  end
end
