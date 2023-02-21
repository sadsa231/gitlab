import { __, s__, n__, sprintf } from '~/locale';

export const JOB_STATUS_GROUP_SUCCESS = 'success';

export const STATUS_BADGE_VARIANTS = {
  success: 'success',
  passed: 'success',
  error: 'danger',
  failed: 'danger',
  pending: 'warning',
  'waiting-for-resource': 'warning',
  'failed-with-warnings': 'warning',
  'success-with-warnings': 'warning',
  running: 'info',
  canceled: 'neutral',
  disabled: 'neutral',
  scheduled: 'neutral',
  manual: 'neutral',
  notification: 'muted',
  preparing: 'muted',
  created: 'muted',
  skipped: 'muted',
  notfound: 'muted',
};

export const I18N_DOWNLOAD = __('Download');
export const I18N_BROWSE = s__('Artifacts|Browse');
export const I18N_DELETE = __('Delete');
export const I18N_EXPIRED = __('Expired');
export const I18N_DESTROY_ERROR = s__('Artifacts|An error occurred while deleting the artifact');
export const I18N_FETCH_ERROR = s__('Artifacts|An error occurred while retrieving job artifacts');
export const I18N_ARTIFACTS = __('Artifacts');
export const I18N_JOB = __('Job');
export const I18N_SIZE = __('Size');
export const I18N_CREATED = __('Created');
export const I18N_ARTIFACTS_COUNT = (count) => n__('%d file', '%d files', count);

export const I18N_MODAL_TITLE = (artifactName) =>
  sprintf(s__('Artifacts|Delete %{name}?'), { name: artifactName });
export const I18N_MODAL_BODY = s__(
  'Artifacts|This artifact will be permanently deleted. Any reports generated from this artifact will be empty.',
);
export const I18N_MODAL_PRIMARY = s__('Artifacts|Delete artifact');
export const I18N_MODAL_CANCEL = __('Cancel');

export const I18N_FEEDBACK_BANNER_TITLE = s__('Artifacts|Help us improve this page');
export const I18N_FEEDBACK_BANNER_BODY = s__(
  'Artifacts|We want you to be able to use this page to easily manage your CI/CD job artifacts. We are working to improve this experience and would appreciate any feedback you have about the improvements we are making.',
);
export const I18N_FEEDBACK_BANNER_BUTTON = s__('Artifacts|Take a quick survey');
export const FEEDBACK_URL = 'https://gitlab.fra1.qualtrics.com/jfe/form/SV_cI9rAUI20Vo2St8';

export const INITIAL_CURRENT_PAGE = 1;
export const INITIAL_PREVIOUS_PAGE_CURSOR = '';
export const INITIAL_NEXT_PAGE_CURSOR = '';
export const JOBS_PER_PAGE = 20;
export const INITIAL_LAST_PAGE_SIZE = null;

export const ARCHIVE_FILE_TYPE = 'ARCHIVE';

export const ARTIFACT_ROW_HEIGHT = 56;
export const ARTIFACTS_SHOWN_WITHOUT_SCROLLING = 4;
