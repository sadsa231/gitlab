import { __, s__ } from '~/locale';

export const DEBOUNCE_DELAY = 500;
export const MAX_RECENT_TOKENS_SIZE = 3;

export const FILTER_NONE = 'None';
export const FILTER_ANY = 'Any';
export const FILTER_CURRENT = 'Current';
export const FILTER_UPCOMING = 'Upcoming';
export const FILTER_STARTED = 'Started';

export const FILTERS_NONE_ANY = [FILTER_NONE, FILTER_ANY];

export const OPERATOR_IS = '=';
export const OPERATOR_IS_TEXT = __('is');
export const OPERATOR_NOT = '!=';
export const OPERATOR_NOT_TEXT = __('is not one of');
export const OPERATOR_OR = '||';
export const OPERATOR_OR_TEXT = __('is one of');

export const OPERATORS_IS = [{ value: OPERATOR_IS, description: OPERATOR_IS_TEXT }];
export const OPERATORS_NOT = [{ value: OPERATOR_NOT, description: OPERATOR_NOT_TEXT }];
export const OPERATORS_OR = [{ value: OPERATOR_OR, description: OPERATOR_OR_TEXT }];
export const OPERATORS_IS_NOT = [...OPERATORS_IS, ...OPERATORS_NOT];
export const OPERATORS_IS_NOT_OR = [...OPERATORS_IS, ...OPERATORS_NOT, ...OPERATORS_OR];

export const OPTION_NONE = { value: FILTER_NONE, text: __('None'), title: __('None') };
export const OPTION_ANY = { value: FILTER_ANY, text: __('Any'), title: __('Any') };
export const OPTION_CURRENT = { value: FILTER_CURRENT, text: __('Current') };
export const OPTION_STARTED = { value: FILTER_STARTED, text: __('Started'), title: __('Started') };
export const OPTION_UPCOMING = {
  value: FILTER_UPCOMING,
  text: __('Upcoming'),
  title: __('Upcoming'),
};

export const OPTIONS_NONE_ANY = [OPTION_NONE, OPTION_ANY];

export const DEFAULT_MILESTONES = OPTIONS_NONE_ANY.concat([OPTION_UPCOMING, OPTION_STARTED]);

export const SORT_DIRECTION = {
  descending: 'descending',
  ascending: 'ascending',
};

export const FILTERED_SEARCH_TERM = 'filtered-search-term';

export const TOKEN_TITLE_APPROVED_BY = __('Approved-By');
export const TOKEN_TITLE_ASSIGNEE = s__('SearchToken|Assignee');
export const TOKEN_TITLE_AUTHOR = __('Author');
export const TOKEN_TITLE_CONFIDENTIAL = __('Confidential');
export const TOKEN_TITLE_CONTACT = s__('Crm|Contact');
export const TOKEN_TITLE_LABEL = __('Label');
export const TOKEN_TITLE_MILESTONE = __('Milestone');
export const TOKEN_TITLE_MY_REACTION = __('My-Reaction');
export const TOKEN_TITLE_ORGANIZATION = s__('Crm|Organization');
export const TOKEN_TITLE_RELEASE = __('Release');
export const TOKEN_TITLE_REVIEWER = s__('SearchToken|Reviewer');
export const TOKEN_TITLE_SOURCE_BRANCH = __('Source Branch');
export const TOKEN_TITLE_STATUS = __('Status');
export const TOKEN_TITLE_TARGET_BRANCH = __('Target Branch');
export const TOKEN_TITLE_TYPE = __('Type');
export const TOKEN_TITLE_SEARCH_WITHIN = __('Search Within');

export const TOKEN_TYPE_APPROVED_BY = 'approved-by';
export const TOKEN_TYPE_ASSIGNEE = 'assignee';
export const TOKEN_TYPE_AUTHOR = 'author';
export const TOKEN_TYPE_CONFIDENTIAL = 'confidential';
export const TOKEN_TYPE_CONTACT = 'contact';
export const TOKEN_TYPE_EPIC = 'epic';
// As health status gets reused between issue lists and boards
// this is in the shared constants. Until we have not decoupled the EE filtered search bar
// from the CE component, we need to keep this in the CE code.
// https://gitlab.com/gitlab-org/gitlab/-/issues/377838
export const TOKEN_TYPE_HEALTH = 'health';
export const TOKEN_TYPE_ITERATION = 'iteration';
export const TOKEN_TYPE_LABEL = 'label';
export const TOKEN_TYPE_MILESTONE = 'milestone';
export const TOKEN_TYPE_MY_REACTION = 'my-reaction';
export const TOKEN_TYPE_ORGANIZATION = 'organization';
export const TOKEN_TYPE_RELEASE = 'release';
export const TOKEN_TYPE_REVIEWER = 'reviewer';
export const TOKEN_TYPE_SOURCE_BRANCH = 'source-branch';
export const TOKEN_TYPE_STATUS = 'status';
export const TOKEN_TYPE_TARGET_BRANCH = 'target-branch';
export const TOKEN_TYPE_TYPE = 'type';
export const TOKEN_TYPE_WEIGHT = 'weight';
export const TOKEN_TYPE_SEARCH_WITHIN = 'in';
