# frozen_string_literal: true

module QA
  RSpec.describe 'Package', :orchestrated, :packages, :object_storage, :reliable, product_group: :package_registry do
    describe 'Maven group level endpoint' do
      include Runtime::Fixtures
      include Support::Helpers::MaskToken
      include_context 'packages registry qa scenario'

      let(:group_id) { 'com.gitlab.qa' }
      let(:artifact_id) { "maven-#{SecureRandom.hex(8)}" }
      let(:package_name) { "#{group_id}/#{artifact_id}".tr('.', '/') }
      let(:package_version) { '1.3.7' }
      let(:package_type) { 'maven' }

      let(:group_deploy_token) do
        Resource::GroupDeployToken.fabricate_via_api! do |deploy_token|
          deploy_token.name = 'maven-group-deploy-token'
          deploy_token.group = package_project.group
          deploy_token.scopes = %w[
            read_repository
            read_package_registry
            write_package_registry
          ]
        end
      end

      context 'via maven' do
        where do
          {
            'using a personal access token' => {
              authentication_token_type: :personal_access_token,
              maven_header_name: 'Private-Token',
              testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347582'
            },
            'using a project deploy token' => {
              authentication_token_type: :project_deploy_token,
              maven_header_name: 'Deploy-Token',
              testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347585'
            },
            'using a ci job token' => {
              authentication_token_type: :ci_job_token,
              maven_header_name: 'Job-Token',
              testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347579'
            }
          }
        end

        with_them do
          let(:token) do
            case authentication_token_type
            when :personal_access_token
              use_ci_variable(name: 'PERSONAL_ACCESS_TOKEN', value: personal_access_token, project: package_project)
              use_ci_variable(name: 'PERSONAL_ACCESS_TOKEN', value: personal_access_token, project: client_project)
            when :ci_job_token
              '${CI_JOB_TOKEN}'
            when :project_deploy_token
              use_ci_variable(name: 'GROUP_DEPLOY_TOKEN', value: group_deploy_token.token, project: package_project)
              use_ci_variable(name: 'GROUP_DEPLOY_TOKEN', value: group_deploy_token.token, project: client_project)
            end
          end

          it 'pushes and pulls a maven package', testcase: params[:testcase] do
            Support::Retrier.retry_on_exception(max_attempts: 3, sleep_interval: 2) do
              Resource::Repository::Commit.fabricate_via_api! do |commit|
                gitlab_ci_yaml = ERB.new(read_fixture('package_managers/maven/group/producer', 'gitlab_ci.yaml.erb')).result(binding)
                pom_xml = ERB.new(read_fixture('package_managers/maven/group/producer', 'pom.xml.erb')).result(binding)
                settings_xml = ERB.new(read_fixture('package_managers/maven/group/producer', 'settings.xml.erb')).result(binding)

                commit.project = package_project
                commit.commit_message = 'Add files'
                commit.add_files(
                  [
                    { file_path: '.gitlab-ci.yml', content: gitlab_ci_yaml },
                    { file_path: 'pom.xml', content: pom_xml },
                    { file_path: 'settings.xml', content: settings_xml }
                  ])
              end
            end

            package_project.visit!

            Flow::Pipeline.visit_latest_pipeline

            Page::Project::Pipeline::Show.perform do |pipeline|
              pipeline.click_job('deploy')
            end

            Page::Project::Job::Show.perform do |job|
              expect(job).to be_successful(timeout: 800)
            end

            Page::Project::Menu.perform(&:click_packages_link)

            Page::Project::Packages::Index.perform do |index|
              expect(index).to have_package(package_name)

              index.click_package(package_name)
            end

            Page::Project::Packages::Show.perform do |show|
              expect(show).to have_package_info(package_name, package_version)
            end

            Support::Retrier.retry_on_exception(max_attempts: 3, sleep_interval: 2) do
              Resource::Repository::Commit.fabricate_via_api! do |commit|
                gitlab_ci_yaml = ERB.new(read_fixture('package_managers/maven/group/consumer', 'gitlab_ci.yaml.erb')).result(binding)
                pom_xml = ERB.new(read_fixture('package_managers/maven/group/consumer', 'pom.xml.erb')).result(binding)
                settings_xml = ERB.new(read_fixture('package_managers/maven/group/consumer', 'settings.xml.erb')).result(binding)

                commit.project = client_project
                commit.commit_message = 'Add files'
                commit.add_files(
                  [
                    { file_path: '.gitlab-ci.yml', content: gitlab_ci_yaml },
                    { file_path: 'pom.xml', content: pom_xml },
                    { file_path: 'settings.xml', content: settings_xml }
                  ])
              end
            end

            client_project.visit!

            Flow::Pipeline.visit_latest_pipeline

            Page::Project::Pipeline::Show.perform do |pipeline|
              pipeline.click_job('install')
            end

            Page::Project::Job::Show.perform do |job|
              expect(job).to be_successful(timeout: 800)
            end
          end
        end
      end

      context 'duplication setting' do
        before do
          use_ci_variable(name: 'PERSONAL_ACCESS_TOKEN', value: personal_access_token, project: package_project)
          use_ci_variable(name: 'PERSONAL_ACCESS_TOKEN', value: personal_access_token, project: client_project)
          package_project.group.visit!
          Page::Group::Menu.perform(&:go_to_package_settings)
        end

        context 'when disabled' do
          before do
            Page::Group::Settings::PackageRegistries.perform(&:set_allow_duplicates_disabled)
          end

          it 'prevents users from publishing duplicates', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/377491' do
            create_package(package_project)
            show_latest_deploy_job

            Page::Project::Job::Show.perform do |job|
              expect(job).to be_successful(timeout: 400)
            end

            Page::Project::Job::Show.perform(&:retry!)

            show_latest_deploy_job

            Page::Project::Job::Show.perform do |job|
              expect(job).not_to be_successful(timeout: 400)
            end
          end
        end

        context 'when enabled' do
          before do
            Page::Group::Settings::PackageRegistries.perform(&:set_allow_duplicates_enabled)
          end

          it 'allows users to publish duplicates', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/377492' do
            create_package(package_project)

            show_latest_deploy_job

            Page::Project::Job::Show.perform do |job|
              expect(job).to be_successful(timeout: 400)
            end

            Page::Project::Job::Show.perform(&:retry!)

            show_latest_deploy_job

            Page::Project::Job::Show.perform do |job|
              expect(job).to be_successful(timeout: 400)
            end
          end
        end

        def create_package(project)
          Support::Retrier.retry_on_exception(max_attempts: 3, sleep_interval: 2) do
            Resource::Repository::Commit.fabricate_via_api! do |commit|
              gitlab_ci_yaml = ERB.new(read_fixture('package_managers/maven/group/producer', 'gitlab_ci.yaml.erb')).result(binding)
              pom_xml = ERB.new(read_fixture('package_managers/maven/group/producer', 'pom.xml.erb')).result(binding)
              settings_xml_with_pat = ERB.new(read_fixture('package_managers/maven/group', 'settings_with_pat.xml.erb')).result(binding)

              commit.project = project
              commit.commit_message = 'Add .gitlab-ci.yml'
              commit.add_files(
                [
                  { file_path: '.gitlab-ci.yml', content: gitlab_ci_yaml },
                  { file_path: 'pom.xml', content: pom_xml },
                  { file_path: 'settings.xml', content: settings_xml_with_pat }
                ])
            end
          end
        end

        def show_latest_deploy_job
          package_project.visit!

          Flow::Pipeline.visit_latest_pipeline

          Page::Project::Pipeline::Show.perform do |pipeline|
            pipeline.click_job('deploy')
          end
        end
      end
    end
  end
end
