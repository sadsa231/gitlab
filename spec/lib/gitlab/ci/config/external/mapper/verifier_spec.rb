# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Config::External::Mapper::Verifier, feature_category: :pipeline_authoring do
  include RepoHelpers
  include StubRequests

  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user) { project.owner }

  let(:context) do
    Gitlab::Ci::Config::External::Context.new(project: project, user: user, sha: project.commit.id)
  end

  let(:remote_url) { 'https://gitlab.com/gitlab-org/gitlab-foss/blob/1234/.gitlab-ci-1.yml' }

  let(:project_files) do
    {
      'myfolder/file1.yml' => <<~YAML,
        my_build:
          script: echo Hello World
      YAML
      'myfolder/file2.yml' => <<~YAML,
        my_test:
          script: echo Hello World
      YAML
      'myfolder/file3.yml' => <<~YAML,
        my_deploy:
          script: echo Hello World
      YAML
      'nested_configs.yml' => <<~YAML
        include:
          - local: myfolder/file1.yml
          - local: myfolder/file2.yml
          - remote: #{remote_url}
      YAML
    }
  end

  around(:all) do |example|
    create_and_delete_files(project, project_files) do
      example.run
    end
  end

  before do
    stub_full_request(remote_url).to_return(
      body: <<~YAML
      remote_test:
        script: echo Hello World
      YAML
    )
  end

  subject(:verifier) { described_class.new(context) }

  describe '#process' do
    subject(:process) { verifier.process(files) }

    context 'when files are local' do
      let(:files) do
        [
          Gitlab::Ci::Config::External::File::Local.new({ local: 'myfolder/file1.yml' }, context),
          Gitlab::Ci::Config::External::File::Local.new({ local: 'myfolder/file2.yml' }, context),
          Gitlab::Ci::Config::External::File::Local.new({ local: 'myfolder/file3.yml' }, context)
        ]
      end

      it 'returns an array of file objects' do
        expect(process.map(&:location)).to contain_exactly(
          'myfolder/file1.yml', 'myfolder/file2.yml', 'myfolder/file3.yml'
        )
      end

      it 'adds files to the expandset' do
        expect { process }.to change { context.expandset.count }.by(3)
      end

      it 'calls Gitaly only once for all files', :request_store do
        # 1 for project.commit.id, 1 for the files
        expect { process }.to change { Gitlab::GitalyClient.get_request_count }.by(2)
      end

      context 'when the FF ci_batch_request_for_local_and_project_includes is disabled' do
        before do
          stub_feature_flags(ci_batch_request_for_local_and_project_includes: false)
        end

        it 'calls Gitaly for each file', :request_store do
          # 1 for project.commit.id, 3 for the files
          expect { process }.to change { Gitlab::GitalyClient.get_request_count }.by(4)
        end
      end
    end

    context 'when files are project files' do
      let_it_be(:included_project) { create(:project, :repository, namespace: project.namespace, creator: user) }

      let(:files) do
        [
          Gitlab::Ci::Config::External::File::Project.new(
            { file: 'myfolder/file1.yml', project: included_project.full_path }, context
          ),
          Gitlab::Ci::Config::External::File::Project.new(
            { file: 'myfolder/file2.yml', project: included_project.full_path }, context
          ),
          Gitlab::Ci::Config::External::File::Project.new(
            { file: 'myfolder/file3.yml', project: included_project.full_path }, context
          )
        ]
      end

      around(:all) do |example|
        create_and_delete_files(included_project, project_files) do
          example.run
        end
      end

      it 'returns an array of file objects' do
        expect(process.map(&:location)).to contain_exactly(
          'myfolder/file1.yml', 'myfolder/file2.yml', 'myfolder/file3.yml'
        )
      end

      it 'adds files to the expandset' do
        expect { process }.to change { context.expandset.count }.by(3)
      end

      it 'calls Gitaly only once for all files', :request_store do
        # 1 for project.commit.id, 3 for the sha check, 1 for the files
        expect { process }.to change { Gitlab::GitalyClient.get_request_count }.by(5)
      end

      context 'when the FF ci_batch_request_for_local_and_project_includes is disabled' do
        before do
          stub_feature_flags(ci_batch_request_for_local_and_project_includes: false)
        end

        it 'calls Gitaly for each file', :request_store do
          # 1 for project.commit.id, 3 for the sha check, 3 for the files
          expect { process }.to change { Gitlab::GitalyClient.get_request_count }.by(7)
        end
      end
    end

    context 'when a file includes other files' do
      let(:files) do
        [
          Gitlab::Ci::Config::External::File::Local.new({ local: 'nested_configs.yml' }, context)
        ]
      end

      it 'returns an array of file objects with combined hash' do
        expect(process.map(&:to_hash)).to contain_exactly(
          { my_build: { script: 'echo Hello World' },
            my_test: { script: 'echo Hello World' },
            remote_test: { script: 'echo Hello World' } }
        )
      end
    end

    context 'when there is an invalid file' do
      let(:files) do
        [
          Gitlab::Ci::Config::External::File::Local.new({ local: 'myfolder/invalid.yml' }, context)
        ]
      end

      it 'adds an error to the file' do
        expect(process.first.errors).to include("Local file `myfolder/invalid.yml` does not exist!")
      end
    end

    context 'when max_includes is exceeded' do
      context 'when files are nested' do
        let(:files) do
          [
            Gitlab::Ci::Config::External::File::Local.new({ local: 'nested_configs.yml' }, context)
          ]
        end

        before do
          allow(context).to receive(:max_includes).and_return(1)
        end

        it 'raises Processor::IncludeError' do
          expect { process }.to raise_error(Gitlab::Ci::Config::External::Processor::IncludeError)
        end
      end

      context 'when files are not nested' do
        let(:files) do
          [
            Gitlab::Ci::Config::External::File::Local.new({ local: 'myfolder/file1.yml' }, context),
            Gitlab::Ci::Config::External::File::Local.new({ local: 'myfolder/file2.yml' }, context)
          ]
        end

        before do
          allow(context).to receive(:max_includes).and_return(1)
        end

        it 'raises Mapper::TooManyIncludesError' do
          expect { process }.to raise_error(Gitlab::Ci::Config::External::Mapper::TooManyIncludesError)
        end
      end
    end
  end
end
