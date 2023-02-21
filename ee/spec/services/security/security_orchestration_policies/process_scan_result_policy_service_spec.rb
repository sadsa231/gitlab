# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::SecurityOrchestrationPolicies::ProcessScanResultPolicyService, feature_category: :security_policy_management do
  describe '#execute' do
    let(:policy_configuration) { create(:security_orchestration_policy_configuration, project: project) }
    let(:project) { create(:project, namespace: group) }

    let(:group) { create(:group, :public) }
    let(:policy) { build(:scan_result_policy, name: 'Test Policy') }
    let(:policy_yaml) { Gitlab::Config::Loader::Yaml.new(policy.to_yaml).load! }
    let(:approver) { create(:user) }
    let(:service) { described_class.new(project: project, policy_configuration: policy_configuration, policy: policy, policy_index: 0) }

    before do
      group.add_maintainer(approver)
      allow(policy_configuration).to receive(:policy_last_updated_by).and_return(approver)
    end

    subject { service.execute }

    context 'without any require_approval action' do
      let(:policy) { build(:scan_result_policy, name: 'Test Policy', actions: [{ type: 'another_one' }]) }

      it 'does not create approval project rules' do
        expect { subject }.not_to change { project.approval_rules.count }
      end
    end

    context 'without any rule of the scan_finding type' do
      let(:policy) { build(:scan_result_policy, name: 'Test Policy', rules: [{ type: 'another_one' }]) }

      it 'does not create approval project rules' do
        expect { subject }.not_to change { project.approval_rules.count }
      end
    end

    shared_examples 'create approval rule with specific approver' do
      it 'succeeds creating approval rules with specific approver' do
        expect { subject }.to change { project.approval_rules.count }.by(1)
        expect(project.approval_rules.first.approvers).to contain_exactly(approver)
      end
    end

    context 'with only user id' do
      let(:policy) { build(:scan_result_policy, name: 'Test Policy', actions: [{ type: 'require_approval', approvals_required: 1, user_approvers_ids: [approver.id] }]) }

      it_behaves_like 'create approval rule with specific approver'
    end

    context 'with only username' do
      let(:policy) { build(:scan_result_policy, name: 'Test Policy', actions: [{ type: 'require_approval', approvals_required: 1, user_approvers: [approver.username] }]) }

      it_behaves_like 'create approval rule with specific approver'
    end

    context 'with only group id' do
      let(:policy) { build(:scan_result_policy, name: 'Test Policy', actions: [{ type: 'require_approval', approvals_required: 1, group_approvers_ids: [group.id] }]) }

      it_behaves_like 'create approval rule with specific approver'

      context 'with public group outside of the scope' do
        let(:another_group) { create(:group, :public) }
        let(:policy) { build(:scan_result_policy, name: 'Test Policy', actions: [{ type: 'require_approval', approvals_required: 1, group_approvers_ids: [another_group.id] }]) }

        it 'does not include any approvers' do
          subject

          expect(project.approval_rules.first.approvers).to be_empty
        end
      end

      context 'with private group outside of the scope' do
        let(:another_group) { create(:group, :private) }
        let(:policy) { build(:scan_result_policy, name: 'Test Policy', actions: [{ type: 'require_approval', approvals_required: 1, group_approvers_ids: [another_group.id] }]) }

        it 'does not include any approvers' do
          subject

          expect(project.approval_rules.first.approvers).to be_empty
        end
      end

      context 'with an invited group' do
        let(:group_user) { create(:user) }
        let(:another_group) { create(:group, :public) }
        let(:policy) { build(:scan_result_policy, name: 'Test Policy', actions: [{ type: 'require_approval', approvals_required: 1, group_approvers_ids: [another_group.id] }]) }

        before do
          another_group.add_maintainer(group_user)
          project.invited_groups = [another_group]
        end

        it 'includes group related approvers' do
          subject

          expect(project.approval_rules.first.approvers).to match_array([group_user])
        end
      end
    end

    context 'with only group path' do
      let(:policy) { build(:scan_result_policy, name: 'Test Policy', actions: [{ type: 'require_approval', approvals_required: 1, group_approvers: [group.path] }]) }

      it_behaves_like 'create approval rule with specific approver'
    end

    context 'with a specific number of rules' do
      using RSpec::Parameterized::TableSyntax

      let(:rule) do
        {
          type: 'scan_finding',
          branches: %w[master],
          scanners: %w[container_scanning],
          vulnerabilities_allowed: 0,
          severity_levels: %w[critical],
          vulnerability_states: %w[detected]
        }
      end

      let(:rules) { [rule] * rules_count }

      let(:policy) { build(:scan_result_policy, name: 'Test Policy', rules: rules) }

      where(:rules_count, :expected_rules_count) do
        [
          [Security::ScanResultPolicy::LIMIT - 1, Security::ScanResultPolicy::LIMIT - 1],
          [Security::ScanResultPolicy::LIMIT, Security::ScanResultPolicy::LIMIT],
          [Security::ScanResultPolicy::LIMIT + 1, Security::ScanResultPolicy::LIMIT]
        ]
      end

      with_them do
        it 'creates approval rules up to limit' do
          subject

          expect(project.approval_rules.count).to be expected_rules_count
        end
      end
    end

    context 'when user does not have edit_approval_rule permission' do
      let(:policy) { build(:scan_result_policy, name: 'Test Policy', actions: [{ type: 'require_approval', approvals_required: 1, user_approvers_ids: [approver.id] }]) }

      before do
        allow(Ability).to receive(:allowed?).and_call_original
        allow(Ability).to receive(:allowed?).with(approver, :edit_approval_rule, project).and_return(false)
      end

      it_behaves_like 'create approval rule with specific approver'
    end

    context 'with empty branches' do
      let(:rule) do
        {
          type: 'scan_finding',
          branches: [],
          scanners: %w[container_scanning],
          vulnerabilities_allowed: 0,
          severity_levels: %w[critical],
          vulnerability_states: %w[detected]
        }
      end

      let(:rules) { [rule] }
      let(:policy) { build(:scan_result_policy, name: 'Test Policy', rules: rules) }

      before do
        create(:protected_branch, project: project)
      end

      it 'sets applies_to_all_protected_branches to true' do
        subject

        expect(project.approval_rules.first.applies_to_all_protected_branches).to be_truthy
        expect(project.approval_rules.first.applies_to_branch?('random-branch')).to be_falsey
      end
    end

    describe 'rule params `protected_branch_ids`' do
      let(:protected_branch_name) { 'protected-branch-name' }
      let(:rule) do
        {
          type: 'scan_finding',
          branches: [protected_branch_name],
          scanners: %w[container_scanning],
          vulnerabilities_allowed: 0,
          severity_levels: %w[critical],
          vulnerability_states: %w[detected]
        }
      end

      let(:policy) { build(:scan_result_policy, name: 'Test Policy', rules: [rule]) }
      let(:scan_finding_rule) { project.approval_rules.first }

      let!(:project_protected_branch) do
        create(:protected_branch, project: project, name: protected_branch_name)
      end

      let!(:group_protected_branch) do
        create(:protected_branch, project: nil, group: group, name: protected_branch_name)
      end

      before do
        stub_licensed_features(multiple_approval_rules: true)
      end

      context 'when feature flag `group_protected_branches` enabled' do
        before do
          stub_feature_flags(group_protected_branches: true)
        end

        it 'set `protected_branch_ids` from the project and group level' do
          subject

          expect(scan_finding_rule.protected_branch_ids).to match_array([
            project_protected_branch.id,
            group_protected_branch.id
          ])
        end
      end

      context 'when feature flag `group_protected_branches` disabled' do
        before do
          stub_feature_flags(group_protected_branches: false)
        end

        it 'set `protected_branch_ids` from only the project level' do
          subject

          expect(scan_finding_rule.protected_branch_ids).to match_array([project_protected_branch.id])
        end
      end
    end

    it 'sets project approval rule based on policy', :aggregate_failures do
      subject

      scan_finding_rule = project.approval_rules.first
      first_rule = policy[:rules].first
      first_action = policy[:actions].first

      expect(scan_finding_rule.name).to include(policy[:name])
      expect(scan_finding_rule.report_type).to eq(Security::ScanResultPolicy::SCAN_FINDING)
      expect(scan_finding_rule.rule_type).to eq('report_approver')
      expect(scan_finding_rule.scanners).to eq(first_rule[:scanners])
      expect(scan_finding_rule.severity_levels).to eq(first_rule[:severity_levels])
      expect(scan_finding_rule.vulnerabilities_allowed).to eq(first_rule[:vulnerabilities_allowed])
      expect(scan_finding_rule.vulnerability_states).to eq(first_rule[:vulnerability_states])
      expect(scan_finding_rule.approvals_required).to eq(first_action[:approvals_required])
      expect(scan_finding_rule.security_orchestration_policy_configuration).to eq(policy_configuration)
      expect(scan_finding_rule.orchestration_policy_idx).to eq(0)
    end
  end
end
