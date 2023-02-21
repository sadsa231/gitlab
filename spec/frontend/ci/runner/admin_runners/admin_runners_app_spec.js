import Vue, { nextTick } from 'vue';
import { GlToast, GlLink } from '@gitlab/ui';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import setWindowLocation from 'helpers/set_window_location_helper';
import {
  extendedWrapper,
  shallowMountExtended,
  mountExtended,
} from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/flash';
import { s__ } from '~/locale';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { updateHistory } from '~/lib/utils/url_utility';

import { upgradeStatusTokenConfig } from 'ee_else_ce/ci/runner/components/search_tokens/upgrade_status_token_config';
import { createLocalState } from '~/ci/runner/graphql/list/local_state';
import AdminRunnersApp from '~/ci/runner/admin_runners/admin_runners_app.vue';
import RunnerTypeTabs from '~/ci/runner/components/runner_type_tabs.vue';
import RunnerFilteredSearchBar from '~/ci/runner/components/runner_filtered_search_bar.vue';
import RunnerList from '~/ci/runner/components/runner_list.vue';
import RunnerListEmptyState from '~/ci/runner/components/runner_list_empty_state.vue';
import RunnerStats from '~/ci/runner/components/stat/runner_stats.vue';
import RunnerActionsCell from '~/ci/runner/components/cells/runner_actions_cell.vue';
import RegistrationDropdown from '~/ci/runner/components/registration/registration_dropdown.vue';
import RunnerPagination from '~/ci/runner/components/runner_pagination.vue';
import RunnerJobStatusBadge from '~/ci/runner/components/runner_job_status_badge.vue';

import {
  ADMIN_FILTERED_SEARCH_NAMESPACE,
  CREATED_ASC,
  CREATED_DESC,
  DEFAULT_SORT,
  I18N_STATUS_ONLINE,
  I18N_STATUS_OFFLINE,
  I18N_STATUS_STALE,
  I18N_INSTANCE_TYPE,
  I18N_GROUP_TYPE,
  I18N_PROJECT_TYPE,
  INSTANCE_TYPE,
  JOBS_ROUTE_PATH,
  PARAM_KEY_PAUSED,
  PARAM_KEY_STATUS,
  PARAM_KEY_TAG,
  STATUS_ONLINE,
  DEFAULT_MEMBERSHIP,
  RUNNER_PAGE_SIZE,
} from '~/ci/runner/constants';
import allRunnersQuery from 'ee_else_ce/ci/runner/graphql/list/all_runners.query.graphql';
import allRunnersCountQuery from 'ee_else_ce/ci/runner/graphql/list/all_runners_count.query.graphql';
import { captureException } from '~/ci/runner/sentry_utils';

import {
  allRunnersData,
  runnersCountData,
  allRunnersDataPaginated,
  onlineContactTimeoutSecs,
  staleTimeoutSecs,
  newRunnerPath,
  emptyPageInfo,
  emptyStateSvgPath,
  emptyStateFilteredSvgPath,
} from '../mock_data';

const mockRegistrationToken = 'MOCK_REGISTRATION_TOKEN';
const mockRunners = allRunnersData.data.runners.nodes;
const mockRunnersCount = runnersCountData.data.runners.count;

const mockRunnersHandler = jest.fn();
const mockRunnersCountHandler = jest.fn();

jest.mock('~/flash');
jest.mock('~/ci/runner/sentry_utils');
jest.mock('~/lib/utils/url_utility', () => ({
  ...jest.requireActual('~/lib/utils/url_utility'),
  updateHistory: jest.fn(),
}));

Vue.use(VueApollo);
Vue.use(GlToast);

const STATUS_COUNT_QUERIES = 3;
const TAB_COUNT_QUERIES = 4;
const COUNT_QUERIES = TAB_COUNT_QUERIES + STATUS_COUNT_QUERIES;

describe('AdminRunnersApp', () => {
  let wrapper;
  let showToast;

  const findRunnerStats = () => wrapper.findComponent(RunnerStats);
  const findRunnerActionsCell = () => wrapper.findComponent(RunnerActionsCell);
  const findRegistrationDropdown = () => wrapper.findComponent(RegistrationDropdown);
  const findRunnerTypeTabs = () => wrapper.findComponent(RunnerTypeTabs);
  const findRunnerList = () => wrapper.findComponent(RunnerList);
  const findRunnerListEmptyState = () => wrapper.findComponent(RunnerListEmptyState);
  const findRunnerPagination = () => extendedWrapper(wrapper.findComponent(RunnerPagination));
  const findRunnerPaginationNext = () => findRunnerPagination().findByText(s__('Pagination|Next'));
  const findRunnerFilteredSearchBar = () => wrapper.findComponent(RunnerFilteredSearchBar);

  const createComponent = ({
    props = {},
    mountFn = shallowMountExtended,
    provide,
    ...options
  } = {}) => {
    const { cacheConfig, localMutations } = createLocalState();

    const handlers = [
      [allRunnersQuery, mockRunnersHandler],
      [allRunnersCountQuery, mockRunnersCountHandler],
    ];

    wrapper = mountFn(AdminRunnersApp, {
      apolloProvider: createMockApollo(handlers, {}, cacheConfig),
      propsData: {
        registrationToken: mockRegistrationToken,
        newRunnerPath,
        ...props,
      },
      provide: {
        localMutations,
        onlineContactTimeoutSecs,
        staleTimeoutSecs,
        emptyStateSvgPath,
        emptyStateFilteredSvgPath,
        ...provide,
      },
      ...options,
    });

    showToast = jest.spyOn(wrapper.vm.$root.$toast, 'show');

    return waitForPromises();
  };

  beforeEach(() => {
    mockRunnersHandler.mockResolvedValue(allRunnersData);
    mockRunnersCountHandler.mockResolvedValue(runnersCountData);
  });

  afterEach(() => {
    mockRunnersHandler.mockReset();
    mockRunnersCountHandler.mockReset();
    showToast.mockReset();
    wrapper.destroy();
  });

  it('shows the runner setup instructions', () => {
    createComponent();

    expect(findRegistrationDropdown().props('registrationToken')).toBe(mockRegistrationToken);
    expect(findRegistrationDropdown().props('type')).toBe(INSTANCE_TYPE);
  });

  describe('shows total runner counts', () => {
    beforeEach(async () => {
      await createComponent({ mountFn: mountExtended });
    });

    it('fetches counts', () => {
      expect(mockRunnersCountHandler).toHaveBeenCalledTimes(COUNT_QUERIES);
    });

    it('shows the runner tabs', () => {
      const tabs = findRunnerTypeTabs().text();
      expect(tabs).toMatchInterpolatedText(
        `All ${mockRunnersCount} ${I18N_INSTANCE_TYPE} ${mockRunnersCount} ${I18N_GROUP_TYPE} ${mockRunnersCount} ${I18N_PROJECT_TYPE} ${mockRunnersCount}`,
      );
    });

    it('shows the total', () => {
      expect(findRunnerStats().text()).toContain(`${I18N_STATUS_ONLINE} ${mockRunnersCount}`);
      expect(findRunnerStats().text()).toContain(`${I18N_STATUS_OFFLINE} ${mockRunnersCount}`);
      expect(findRunnerStats().text()).toContain(`${I18N_STATUS_STALE} ${mockRunnersCount}`);
    });
  });

  describe('does not show total runner counts when total is 0', () => {
    beforeEach(async () => {
      mockRunnersCountHandler.mockResolvedValue({
        data: {
          runners: {
            count: 0,
            ...runnersCountData.runners,
          },
        },
      });

      await createComponent({ mountFn: mountExtended });
    });

    it('fetches only tab counts', () => {
      expect(mockRunnersCountHandler).toHaveBeenCalledTimes(TAB_COUNT_QUERIES);
    });

    it('does not shows counters', () => {
      expect(findRunnerStats().text()).toBe('');
    });
  });

  it('shows the runners list', async () => {
    await createComponent();

    expect(mockRunnersHandler).toHaveBeenCalledTimes(1);
    expect(findRunnerList().props('runners')).toEqual(mockRunners);
  });

  it('runner item links to the runner admin page', async () => {
    await createComponent({ mountFn: mountExtended });

    const { id, shortSha } = mockRunners[0];
    const numericId = getIdFromGraphQLId(id);

    const runnerLink = wrapper.find('tr [data-testid="td-summary"]').findComponent(GlLink);

    expect(runnerLink.text()).toBe(`#${numericId} (${shortSha})`);
    expect(runnerLink.attributes('href')).toBe(`http://localhost/admin/runners/${numericId}`);
  });

  it('renders runner actions for each runner', async () => {
    await createComponent({ mountFn: mountExtended });

    const runnerActions = wrapper
      .find('tr [data-testid="td-actions"]')
      .findComponent(RunnerActionsCell);
    const runner = mockRunners[0];

    expect(runnerActions.props()).toEqual({
      runner,
      editUrl: runner.editAdminUrl,
    });
  });

  it('requests the runners with no filters', async () => {
    await createComponent();

    expect(mockRunnersHandler).toHaveBeenLastCalledWith({
      status: undefined,
      type: undefined,
      membership: DEFAULT_MEMBERSHIP,
      sort: DEFAULT_SORT,
      first: RUNNER_PAGE_SIZE,
    });
  });

  it('sets tokens in the filtered search', () => {
    createComponent();

    expect(findRunnerFilteredSearchBar().props('tokens')).toEqual([
      expect.objectContaining({
        type: PARAM_KEY_PAUSED,
        options: expect.any(Array),
      }),
      expect.objectContaining({
        type: PARAM_KEY_STATUS,
        options: expect.any(Array),
      }),
      expect.objectContaining({
        type: PARAM_KEY_TAG,
        recentSuggestionsStorageKey: `${ADMIN_FILTERED_SEARCH_NAMESPACE}-recent-tags`,
      }),
      upgradeStatusTokenConfig,
    ]);
  });

  describe('Single runner row', () => {
    const { id: graphqlId, shortSha } = mockRunners[0];
    const id = getIdFromGraphQLId(graphqlId);

    beforeEach(async () => {
      mockRunnersCountHandler.mockClear();

      await createComponent({ mountFn: mountExtended });
    });

    it('Links to the runner page', async () => {
      const runnerLink = wrapper.find('tr [data-testid="td-summary"]').findComponent(GlLink);

      expect(runnerLink.text()).toBe(`#${id} (${shortSha})`);
      expect(runnerLink.attributes('href')).toBe(`http://localhost/admin/runners/${id}`);
    });

    it('Shows job status and links to jobs', () => {
      const badge = wrapper
        .find('tr [data-testid="td-status"]')
        .findComponent(RunnerJobStatusBadge);

      expect(badge.props('jobStatus')).toBe(mockRunners[0].jobExecutionStatus);

      const badgeHref = new URL(badge.attributes('href'));
      expect(badgeHref.pathname).toBe(`/admin/runners/${id}`);
      expect(badgeHref.hash).toBe(`#${JOBS_ROUTE_PATH}`);
    });

    it('When runner is paused or unpaused, some data is refetched', async () => {
      expect(mockRunnersCountHandler).toHaveBeenCalledTimes(COUNT_QUERIES);

      findRunnerActionsCell().vm.$emit('toggledPaused');

      expect(mockRunnersCountHandler).toHaveBeenCalledTimes(COUNT_QUERIES * 2);
      expect(showToast).toHaveBeenCalledTimes(0);
    });

    it('When runner is deleted, data is refetched and a toast message is shown', async () => {
      findRunnerActionsCell().vm.$emit('deleted', { message: 'Runner deleted' });

      expect(showToast).toHaveBeenCalledTimes(1);
      expect(showToast).toHaveBeenCalledWith('Runner deleted');
    });
  });

  describe('when a filter is preselected', () => {
    beforeEach(async () => {
      setWindowLocation(`?status[]=${STATUS_ONLINE}&runner_type[]=${INSTANCE_TYPE}&paused[]=true`);

      await createComponent({ mountFn: mountExtended });
    });

    it('sets the filters in the search bar', () => {
      expect(findRunnerFilteredSearchBar().props('value')).toEqual({
        runnerType: INSTANCE_TYPE,
        membership: DEFAULT_MEMBERSHIP,
        filters: [
          { type: PARAM_KEY_STATUS, value: { data: STATUS_ONLINE, operator: '=' } },
          { type: PARAM_KEY_PAUSED, value: { data: 'true', operator: '=' } },
        ],
        sort: 'CREATED_DESC',
        pagination: {},
      });
    });

    it('requests the runners with filter parameters', () => {
      expect(mockRunnersHandler).toHaveBeenLastCalledWith({
        status: STATUS_ONLINE,
        type: INSTANCE_TYPE,
        membership: DEFAULT_MEMBERSHIP,
        paused: true,
        sort: DEFAULT_SORT,
        first: RUNNER_PAGE_SIZE,
      });
    });

    it('fetches count results for requested status', () => {
      expect(mockRunnersCountHandler).toHaveBeenCalledWith({
        type: INSTANCE_TYPE,
        membership: DEFAULT_MEMBERSHIP,
        status: STATUS_ONLINE,
        paused: true,
      });
    });
  });

  describe('when a filter is selected by the user', () => {
    beforeEach(async () => {
      await createComponent({ mountFn: mountExtended });

      findRunnerFilteredSearchBar().vm.$emit('input', {
        runnerType: null,
        membership: DEFAULT_MEMBERSHIP,
        filters: [{ type: PARAM_KEY_STATUS, value: { data: STATUS_ONLINE, operator: '=' } }],
        sort: CREATED_ASC,
      });

      await nextTick();
    });

    it('updates the browser url', () => {
      expect(updateHistory).toHaveBeenLastCalledWith({
        title: expect.any(String),
        url: expect.stringContaining('?status[]=ONLINE&sort=CREATED_ASC'),
      });
    });

    it('requests the runners with filters', () => {
      expect(mockRunnersHandler).toHaveBeenLastCalledWith({
        status: STATUS_ONLINE,
        membership: DEFAULT_MEMBERSHIP,
        sort: CREATED_ASC,
        first: RUNNER_PAGE_SIZE,
      });
    });

    it('fetches count results for requested status', () => {
      expect(mockRunnersCountHandler).toHaveBeenCalledWith({
        status: STATUS_ONLINE,
        membership: DEFAULT_MEMBERSHIP,
      });
    });
  });

  it('when runners have not loaded, shows a loading state', () => {
    createComponent();
    expect(findRunnerList().props('loading')).toBe(true);
    expect(findRunnerPagination().attributes('disabled')).toBe('true');
  });

  describe('Bulk delete', () => {
    describe('Before runners are deleted', () => {
      beforeEach(async () => {
        await createComponent({ mountFn: mountExtended });
      });

      it('runner list is checkable', () => {
        expect(findRunnerList().props('checkable')).toBe(true);
      });
    });

    describe('When runners are deleted', () => {
      beforeEach(async () => {
        await createComponent({ mountFn: mountExtended });
      });

      it('count data is refetched', async () => {
        expect(mockRunnersCountHandler).toHaveBeenCalledTimes(COUNT_QUERIES);

        findRunnerList().vm.$emit('deleted', { message: 'Runners deleted' });

        expect(mockRunnersCountHandler).toHaveBeenCalledTimes(COUNT_QUERIES * 2);
      });

      it('toast is shown', async () => {
        expect(showToast).toHaveBeenCalledTimes(0);

        findRunnerList().vm.$emit('deleted', { message: 'Runners deleted' });

        expect(showToast).toHaveBeenCalledTimes(1);
        expect(showToast).toHaveBeenCalledWith('Runners deleted');
      });
    });
  });

  describe('when no runners are found', () => {
    beforeEach(async () => {
      mockRunnersHandler.mockResolvedValue({
        data: {
          runners: {
            nodes: [],
            pageInfo: emptyPageInfo,
          },
        },
      });

      await createComponent();
    });

    it('shows no errors', () => {
      expect(createAlert).not.toHaveBeenCalled();
    });

    it('shows an empty state', () => {
      expect(findRunnerListEmptyState().props()).toEqual({
        newRunnerPath,
        isSearchFiltered: false,
        filteredSvgPath: emptyStateFilteredSvgPath,
        registrationToken: mockRegistrationToken,
        svgPath: emptyStateSvgPath,
      });
    });

    describe('when a filter is selected by the user', () => {
      beforeEach(async () => {
        findRunnerFilteredSearchBar().vm.$emit('input', {
          runnerType: null,
          membership: DEFAULT_MEMBERSHIP,
          filters: [{ type: PARAM_KEY_STATUS, value: { data: STATUS_ONLINE, operator: '=' } }],
          sort: CREATED_ASC,
        });
        await waitForPromises();
      });

      it('shows an empty state for a filtered search', () => {
        expect(findRunnerListEmptyState().props('isSearchFiltered')).toBe(true);
      });
    });
  });

  describe('when runners query fails', () => {
    beforeEach(async () => {
      mockRunnersHandler.mockRejectedValue(new Error('Error!'));
      await createComponent();
    });

    it('error is shown to the user', async () => {
      expect(createAlert).toHaveBeenCalledTimes(1);
    });

    it('error is reported to sentry', async () => {
      expect(captureException).toHaveBeenCalledWith({
        error: new Error('Error!'),
        component: 'AdminRunnersApp',
      });
    });
  });

  describe('Pagination', () => {
    const { pageInfo } = allRunnersDataPaginated.data.runners;

    beforeEach(async () => {
      mockRunnersHandler.mockResolvedValue(allRunnersDataPaginated);

      await createComponent({ mountFn: mountExtended });
    });

    it('passes the page info', () => {
      expect(findRunnerPagination().props('pageInfo')).toEqual(pageInfo);
    });

    it('navigates to the next page', async () => {
      await findRunnerPaginationNext().trigger('click');

      expect(mockRunnersHandler).toHaveBeenLastCalledWith({
        membership: DEFAULT_MEMBERSHIP,
        sort: CREATED_DESC,
        first: RUNNER_PAGE_SIZE,
        after: pageInfo.endCursor,
      });
    });
  });
});
