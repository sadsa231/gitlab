# frozen_string_literal: true

require 'spec_helper'

module MergeRequests
  class ExampleService < MergeRequests::BaseService
    def execute(merge_request, async: false, allow_duplicate: false)
      create_pipeline_for(merge_request, current_user, async: async, allow_duplicate: allow_duplicate)
    end
  end
end

RSpec.describe MergeRequests::BaseService, feature_category: :code_review_workflow do
  include ProjectForksHelper

  let_it_be(:project) { create(:project, :repository) }

  let(:title) { 'Awesome merge_request' }
  let(:params) do
    {
      title: title,
      description: 'please fix',
      source_branch: 'feature',
      target_branch: 'master'
    }
  end

  subject { MergeRequests::CreateService.new(project: project, current_user: project.first_owner, params: params) }

  describe '#execute_hooks' do
    shared_examples 'enqueues Jira sync worker' do
      specify :aggregate_failures do
        expect(JiraConnect::SyncMergeRequestWorker).to receive(:perform_async).with(kind_of(Numeric), kind_of(Numeric)).and_call_original
        Sidekiq::Testing.fake! do
          expect { subject.execute }.to change(JiraConnect::SyncMergeRequestWorker.jobs, :size).by(1)
        end
      end
    end

    shared_examples 'does not enqueue Jira sync worker' do
      it do
        Sidekiq::Testing.fake! do
          expect { subject.execute }.not_to change(JiraConnect::SyncMergeRequestWorker.jobs, :size)
        end
      end
    end

    context 'with a Jira subscription' do
      before do
        create(:jira_connect_subscription, namespace: project.namespace)
      end

      context 'MR contains Jira issue key' do
        let(:title) { 'Awesome merge_request with issue JIRA-123' }

        it_behaves_like 'enqueues Jira sync worker'
      end

      context 'MR does not contain Jira issue key' do
        it_behaves_like 'does not enqueue Jira sync worker'
      end
    end

    context 'without a Jira subscription' do
      it_behaves_like 'does not enqueue Jira sync worker'
    end
  end

  describe `#create_pipeline_for` do
    let_it_be(:merge_request) { create(:merge_request) }

    subject { MergeRequests::ExampleService.new(project: project, current_user: project.first_owner, params: params) }

    context 'async: false' do
      it 'creates a pipeline directly' do
        expect(MergeRequests::CreatePipelineService)
          .to receive(:new)
          .with(hash_including(project: project, current_user: project.first_owner, params: { allow_duplicate: false }))
          .and_call_original
        expect(MergeRequests::CreatePipelineWorker).not_to receive(:perform_async)

        subject.execute(merge_request, async: false)
      end

      context 'allow_duplicate: true' do
        it 'passes :allow_duplicate as true' do
          expect(MergeRequests::CreatePipelineService)
          .to receive(:new)
          .with(hash_including(project: project, current_user: project.first_owner, params: { allow_duplicate: true }))
          .and_call_original
          expect(MergeRequests::CreatePipelineWorker).not_to receive(:perform_async)

          subject.execute(merge_request, async: false, allow_duplicate: true)
        end
      end
    end

    context 'async: true' do
      it 'enques a CreatePipelineWorker' do
        expect(MergeRequests::CreatePipelineService).not_to receive(:new)
        expect(MergeRequests::CreatePipelineWorker)
          .to receive(:perform_async)
          .with(project.id, project.first_owner.id, merge_request.id, { "allow_duplicate" => false })
          .and_call_original

        Sidekiq::Testing.fake! do
          expect { subject.execute(merge_request, async: true) }.to change(MergeRequests::CreatePipelineWorker.jobs, :size).by(1)
        end
      end

      context 'allow_duplicate: true' do
        it 'passes :allow_duplicate as true' do
          expect(MergeRequests::CreatePipelineService).not_to receive(:new)
          expect(MergeRequests::CreatePipelineWorker)
            .to receive(:perform_async)
            .with(project.id, project.first_owner.id, merge_request.id, { "allow_duplicate" => true })
            .and_call_original

          Sidekiq::Testing.fake! do
            expect { subject.execute(merge_request, async: true, allow_duplicate: true) }.to change(MergeRequests::CreatePipelineWorker.jobs, :size).by(1)
          end
        end
      end
    end
  end
end
