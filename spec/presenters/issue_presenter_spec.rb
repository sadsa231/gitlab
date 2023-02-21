# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IssuePresenter do
  include Gitlab::Routing.url_helpers

  let_it_be(:user) { create(:user) }
  let_it_be(:reporter) { create(:user) }
  let_it_be(:guest) { create(:user) }
  let_it_be(:developer) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:issue) { create(:issue, project: project) }
  let_it_be(:task) { create(:issue, :task, project: project) }
  let_it_be(:non_member) { create(:user) }

  let(:presented_issue) { issue }
  let(:presenter) { described_class.new(presented_issue, current_user: user) }
  let(:obfuscated_email) { 'an*****@e*****.c**' }
  let(:email) { 'any@email.com' }

  before_all do
    group.add_developer(user)
    group.add_developer(developer)
    group.add_reporter(reporter)
    group.add_guest(guest)
  end

  describe '#web_url' do
    it 'returns correct path' do
      expect(presenter.web_url).to eq("http://localhost/#{group.name}/#{project.name}/-/issues/#{presented_issue.iid}")
    end

    context 'when issue type is task' do
      let(:presented_issue) { task }

      context 'when use_iid_in_work_items_path feature flag is disabled' do
        before do
          stub_feature_flags(use_iid_in_work_items_path: false)
        end

        it 'returns a work item url for the task' do
          expect(presenter.web_url).to eq(project_work_items_url(project, work_items_path: presented_issue.id))
        end
      end

      it 'returns a work item url using iid for the task' do
        expect(presenter.web_url).to eq(
          project_work_items_url(project, work_items_path: presented_issue.iid, iid_path: true)
        )
      end
    end
  end

  describe '#subscribed?' do
    subject { presenter.subscribed? }

    it 'returns not subscribed' do
      is_expected.to be(false)
    end

    it 'returns subscribed' do
      create(:subscription, user: user, project: project, subscribable: presented_issue, subscribed: true)

      is_expected.to be(true)
    end
  end

  describe '#issue_path' do
    it 'returns correct path' do
      expect(presenter.issue_path).to eq("/#{group.name}/#{project.name}/-/issues/#{presented_issue.iid}")
    end

    context 'when issue type is task' do
      let(:presented_issue) { task }

      context 'when use_iid_in_work_items_path feature flag is disabled' do
        before do
          stub_feature_flags(use_iid_in_work_items_path: false)
        end

        it 'returns a work item path for the task' do
          expect(presenter.issue_path).to eq(project_work_items_path(project, work_items_path: presented_issue.id))
        end
      end

      it 'returns a work item path using iid for the task' do
        expect(presenter.issue_path).to eq(
          project_work_items_path(project, work_items_path: presented_issue.iid, iid_path: true)
        )
      end
    end
  end

  describe '#project_emails_disabled?' do
    subject { presenter.project_emails_disabled? }

    it 'returns false when emails notifications is enabled for project' do
      is_expected.to be(false)
    end

    context 'when emails notifications is disabled for project' do
      before do
        allow(project).to receive(:emails_disabled?).and_return(true)
      end

      it { is_expected.to be(true) }
    end
  end

  describe '#service_desk_reply_to' do
    context 'when issue is not a service desk issue' do
      subject { presenter.service_desk_reply_to }

      it { is_expected.to be_nil }
    end

    context 'when issue is a service desk issue' do
      let(:service_desk_issue) do
        create(:issue, project: project, author: User.support_bot, service_desk_reply_to: email)
      end

      let(:user) { nil }

      subject { described_class.new(service_desk_issue, current_user: user).service_desk_reply_to }

      it { is_expected.to eq obfuscated_email }

      context 'with signed in user' do
        context 'when user has no role in project' do
          let(:user) { non_member }

          it { is_expected.to eq obfuscated_email }
        end

        context 'when user has guest role in project' do
          let(:user) { guest }

          it { is_expected.to eq obfuscated_email }
        end

        context 'when user has reporter role in project' do
          let(:user) { reporter }

          it { is_expected.to eq email }
        end

        context 'when user has developer role in project' do
          let(:user) { developer }

          it { is_expected.to eq email }
        end
      end
    end
  end

  describe '#issue_email_participants' do
    let(:participants_issue) { create(:issue, project: project) }

    subject { described_class.new(participants_issue, current_user: user).issue_email_participants }

    it { is_expected.to be_empty }

    context "when an issue email participant exists" do
      before do
        participants_issue.issue_email_participants.create!(email: email)
      end

      it "has one element that is a presenter" do
        expect(subject.size).to eq(1)
        expect(subject.first).to be_a(IssueEmailParticipantPresenter)
      end
    end
  end
end
