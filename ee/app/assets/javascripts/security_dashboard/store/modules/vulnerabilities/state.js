export default () => ({
  isLoadingVulnerabilities: true,
  errorLoadingVulnerabilities: false,
  loadingVulnerabilitiesErrorCode: null,
  vulnerabilities: [],
  errorLoadingVulnerabilitiesCount: false,
  vulnerabilitiesCount: {},
  pageInfo: {},
  pipelineId: null,
  vulnerabilitiesEndpoint: null,
  activeVulnerability: null,
  sourceBranch: null,
  modal: {
    vulnerability: {},
    project: {},
    isCommentingOnDismissal: false,
    isShowingDeleteButtons: false,
  },
  isDismissingVulnerability: false,
  isDismissingVulnerabilities: false,
  selectedVulnerabilities: {},
  isCreatingIssue: false,
  isCreatingMergeRequest: false,
});