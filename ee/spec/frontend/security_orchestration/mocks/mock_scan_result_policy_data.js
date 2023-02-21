export const mockDefaultBranchesScanResultManifest = `type: scan_result_policy
name: critical vulnerability CS approvals
description: This policy enforces critical vulnerability CS approvals
enabled: true
rules:
  - type: scan_finding
    branches: []
    scanners:
      - container_scanning
    vulnerabilities_allowed: 1
    severity_levels:
      - critical
    vulnerability_states:
      - newly_detected
actions:
  - type: require_approval
    approvals_required: 1
    user_approvers:
      - the.one
`;

export const mockDefaultBranchesScanResultObject = {
  type: 'scan_result_policy',
  name: 'critical vulnerability CS approvals',
  description: 'This policy enforces critical vulnerability CS approvals',
  enabled: true,
  rules: [
    {
      type: 'scan_finding',
      branches: [],
      scanners: ['container_scanning'],
      vulnerabilities_allowed: 1,
      severity_levels: ['critical'],
      vulnerability_states: ['newly_detected'],
    },
  ],
  actions: [
    {
      type: 'require_approval',
      approvals_required: 1,
      user_approvers: ['the.one'],
    },
  ],
};

export const mockProjectScanResultPolicy = {
  __typename: 'ScanResultPolicy',
  name: mockDefaultBranchesScanResultObject.name,
  updatedAt: new Date('2021-06-07T00:00:00.000Z'),
  yaml: mockDefaultBranchesScanResultManifest,
  enabled: false,
  userApprovers: [],
  groupApprovers: [],
  source: {
    __typename: 'ProjectSecurityPolicySource',
    project: {
      fullPath: 'project/path',
    },
  },
};

export const mockGroupScanResultPolicy = {
  __typename: 'ScanResultPolicy',
  name: mockDefaultBranchesScanResultObject.name,
  updatedAt: new Date('2021-06-07T00:00:00.000Z'),
  yaml: mockDefaultBranchesScanResultManifest,
  enabled: mockDefaultBranchesScanResultObject.enabled,
  userApprovers: [],
  groupApprovers: [],
  source: {
    __typename: 'GroupSecurityPolicySource',
    inherited: true,
    namespace: {
      __typename: 'Namespace',
      id: '1',
      fullPath: 'parent-group-path',
      name: 'parent-group-name',
    },
  },
};

export const mockWithBranchesScanResultManifest = `type: scan_result_policy
name: low vulnerability SAST approvals
description: This policy enforces low vulnerability SAST approvals
enabled: true
rules:
  - type: scan_finding
    branches:
      - main
    scanners:
      - sast
    vulnerabilities_allowed: 1
    severity_levels:
      - low
    vulnerability_states:
      - newly_detected
actions:
  - type: require_approval
    approvals_required: 1
    user_approvers:
      - the.one
`;

export const mockProjectWithBranchesScanResultPolicy = {
  __typename: 'ScanResultPolicy',
  name: 'low vulnerability SAST approvals',
  updatedAt: new Date('2021-06-07T00:00:00.000Z'),
  yaml: mockWithBranchesScanResultManifest,
  enabled: true,
  userApprovers: ['the.one'],
  groupApprovers: [],
  source: {
    __typename: 'ProjectSecurityPolicySource',
    project: {
      fullPath: 'project/path/second',
    },
  },
};

export const mockScanResultPoliciesResponse = [
  mockProjectScanResultPolicy,
  mockGroupScanResultPolicy,
];

export const createRequiredApprovers = (count) => {
  const approvers = [];
  for (let i = 0; i < count; i += 1) {
    const id = i + 1;
    const approver = { webUrl: `webUrl${id}` };
    if (i % 2) {
      // eslint-disable-next-line no-underscore-dangle
      approver.__typename = 'UserCore';
      approver.name = `username${id}`;
      approver.id = `gid://gitlab/User/${id}`;
    } else {
      // eslint-disable-next-line no-underscore-dangle
      approver.__typename = 'Group';
      approver.fullPath = `grouppath${id}`;
      approver.id = `gid://gitlab/Group/${id}`;
    }
    approvers.push(approver);
  }
  return approvers;
};
