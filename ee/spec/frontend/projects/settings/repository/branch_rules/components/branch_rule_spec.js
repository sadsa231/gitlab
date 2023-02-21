import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import BranchRule, {
  i18n,
} from '~/projects/settings/repository/branch_rules/components/branch_rule.vue';
import { sprintf, n__ } from '~/locale';
import { branchRuleProvideMock, branchRulePropsMock } from '../mock_data';

describe('Branch rule', () => {
  let wrapper;

  const createComponent = (props = {}) => {
    wrapper = shallowMountExtended(BranchRule, {
      provide: branchRuleProvideMock,
      propsData: { ...branchRulePropsMock, ...props },
    });
  };

  const findProtectionDetailsListItems = () => wrapper.findAllByRole('listitem');

  beforeEach(() => createComponent());

  it('renders the protection details list items', () => {
    expect(findProtectionDetailsListItems()).toHaveLength(wrapper.vm.approvalDetails.length);
    expect(findProtectionDetailsListItems().at(0).text()).toBe(i18n.allowForcePush);
    expect(findProtectionDetailsListItems().at(1).text()).toBe(i18n.codeOwnerApprovalRequired);
    expect(findProtectionDetailsListItems().at(2).text()).toMatchInterpolatedText(
      sprintf(i18n.statusChecks, {
        total: branchRulePropsMock.statusChecksTotal,
        subject: n__('check', 'checks', branchRulePropsMock.statusChecksTotal),
      }),
    );
    expect(findProtectionDetailsListItems().at(3).text()).toMatchInterpolatedText(
      sprintf(i18n.approvalRules, {
        total: branchRulePropsMock.approvalRulesTotal,
        subject: n__('rule', 'rules', branchRulePropsMock.approvalRulesTotal),
      }),
    );
    expect(findProtectionDetailsListItems().at(4).text()).toBe(wrapper.vm.pushAccessLevelsText);
  });

  it('renders branches count for wildcards', () => {
    createComponent({ name: 'test-*' });
    expect(findProtectionDetailsListItems().at(0).text()).toMatchInterpolatedText(
      sprintf(i18n.matchingBranches, {
        total: branchRulePropsMock.matchingBranchesCount,
        subject: n__('branch', 'branches', branchRulePropsMock.matchingBranchesCount),
      }),
    );
  });
});
