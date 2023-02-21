# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IncidentManagement::TimelineEventTags::CreateService do
  let_it_be(:user_with_permissions) { create(:user) }
  let_it_be(:user_without_permissions) { create(:user) }
  let_it_be_with_reload(:project) { create(:project) }

  let(:current_user) { user_with_permissions }
  let(:args) { { 'name': 'Test tag 1', 'project_path': project.full_path } }

  let(:service) { described_class.new(project, current_user, args) }

  before do
    project.add_maintainer(user_with_permissions)
    project.add_developer(user_without_permissions)
  end

  describe '#execute' do
    shared_examples 'error response' do |message|
      it 'has an informative message' do
        expect(execute).to be_error
        expect(execute.message).to eq(message)
      end
    end

    shared_examples 'success response' do
      it 'has timeline event tag' do
        expect(execute).to be_success

        result = execute.payload[:timeline_event_tag]
        expect(result).to be_a(::IncidentManagement::TimelineEventTag)
        expect(result.name).to eq(args[:name])
        expect(result.project).to eq(project)
      end
    end

    subject(:execute) { service.execute }

    context 'when current user is nil' do
      let(:current_user) { nil }

      it_behaves_like 'error response',
        'You have insufficient permissions to manage timeline event tags for this project'
    end

    context 'when user does not have permissions to create tags' do
      let(:current_user) { user_without_permissions }

      it_behaves_like 'error response',
        'You have insufficient permissions to manage timeline event tags for this project'
    end

    context 'when error occurs during creation' do
      let(:args) { {} }

      it_behaves_like 'error response', "Name can't be blank and Name is invalid"
    end

    context 'when user has permissions' do
      it_behaves_like 'success response'

      it 'creates database record' do
        expect { execute }.to change {
          ::IncidentManagement::TimelineEventTag.where(project_id: project.id).count
        }.by(1)
      end
    end
  end
end
