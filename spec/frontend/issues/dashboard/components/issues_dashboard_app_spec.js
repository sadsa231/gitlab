import { GlEmptyState } from '@gitlab/ui';
import * as Sentry from '@sentry/browser';
import AxiosMockAdapter from 'axios-mock-adapter';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { cloneDeep } from 'lodash';
import getIssuesQuery from 'ee_else_ce/issues/dashboard/queries/get_issues.query.graphql';
import IssueCardStatistics from 'ee_else_ce/issues/list/components/issue_card_statistics.vue';
import IssueCardTimeInfo from 'ee_else_ce/issues/list/components/issue_card_time_info.vue';
import createMockApollo from 'helpers/mock_apollo_helper';
import setWindowLocation from 'helpers/set_window_location_helper';
import { TEST_HOST } from 'helpers/test_constants';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import {
  filteredTokens,
  locationSearch,
  setSortPreferenceMutationResponse,
  setSortPreferenceMutationResponseWithErrors,
} from 'jest/issues/list/mock_data';
import IssuesDashboardApp from '~/issues/dashboard/components/issues_dashboard_app.vue';
import getIssuesCountsQuery from '~/issues/dashboard/queries/get_issues_counts.query.graphql';
import { CREATED_DESC, i18n, UPDATED_DESC, urlSortParams } from '~/issues/list/constants';
import setSortPreferenceMutation from '~/issues/list/queries/set_sort_preference.mutation.graphql';
import { getSortKey, getSortOptions } from '~/issues/list/utils';
import axios from '~/lib/utils/axios_utils';
import { scrollUp } from '~/lib/utils/scroll_utils';
import {
  TOKEN_TYPE_ASSIGNEE,
  TOKEN_TYPE_AUTHOR,
  TOKEN_TYPE_CONFIDENTIAL,
  TOKEN_TYPE_LABEL,
  TOKEN_TYPE_MILESTONE,
  TOKEN_TYPE_MY_REACTION,
  TOKEN_TYPE_SEARCH_WITHIN,
  TOKEN_TYPE_TYPE,
} from '~/vue_shared/components/filtered_search_bar/constants';
import IssuableList from '~/vue_shared/issuable/list/components/issuable_list_root.vue';
import { IssuableStates } from '~/vue_shared/issuable/list/constants';
import {
  emptyIssuesQueryResponse,
  issuesCountsQueryResponse,
  issuesQueryResponse,
} from '../mock_data';

jest.mock('@sentry/browser');
jest.mock('~/lib/utils/scroll_utils', () => ({ scrollUp: jest.fn() }));

describe('IssuesDashboardApp component', () => {
  let axiosMock;
  let wrapper;

  Vue.use(VueApollo);

  const defaultProvide = {
    autocompleteAwardEmojisPath: 'autocomplete/award/emojis/path',
    calendarPath: 'calendar/path',
    dashboardLabelsPath: 'dashboard/labels/path',
    dashboardMilestonesPath: 'dashboard/milestones/path',
    emptyStateWithFilterSvgPath: 'empty/state/with/filter/svg/path.svg',
    emptyStateWithoutFilterSvgPath: 'empty/state/with/filter/svg/path.svg',
    hasBlockedIssuesFeature: true,
    hasIssuableHealthStatusFeature: true,
    hasIssueWeightsFeature: true,
    hasScopedLabelsFeature: true,
    initialSort: CREATED_DESC,
    isPublicVisibilityRestricted: false,
    isSignedIn: true,
    rssPath: 'rss/path',
  };

  let defaultQueryResponse = issuesQueryResponse;
  if (IS_EE) {
    defaultQueryResponse = cloneDeep(issuesQueryResponse);
    defaultQueryResponse.data.issues.nodes[0].blockingCount = 1;
    defaultQueryResponse.data.issues.nodes[0].healthStatus = null;
    defaultQueryResponse.data.issues.nodes[0].weight = 5;
  }

  const findCalendarButton = () => wrapper.findByRole('link', { name: i18n.calendarLabel });
  const findEmptyState = () => wrapper.findComponent(GlEmptyState);
  const findIssuableList = () => wrapper.findComponent(IssuableList);
  const findIssueCardStatistics = () => wrapper.findComponent(IssueCardStatistics);
  const findIssueCardTimeInfo = () => wrapper.findComponent(IssueCardTimeInfo);
  const findRssButton = () => wrapper.findByRole('link', { name: i18n.rssLabel });

  const mountComponent = ({
    provide = {},
    issuesQueryHandler = jest.fn().mockResolvedValue(defaultQueryResponse),
    issuesCountsQueryHandler = jest.fn().mockResolvedValue(issuesCountsQueryResponse),
    sortPreferenceMutationHandler = jest.fn().mockResolvedValue(setSortPreferenceMutationResponse),
  } = {}) => {
    wrapper = mountExtended(IssuesDashboardApp, {
      apolloProvider: createMockApollo([
        [getIssuesQuery, issuesQueryHandler],
        [getIssuesCountsQuery, issuesCountsQueryHandler],
        [setSortPreferenceMutation, sortPreferenceMutationHandler],
      ]),
      provide: {
        ...defaultProvide,
        ...provide,
      },
    });
  };

  beforeEach(() => {
    setWindowLocation(TEST_HOST);
    axiosMock = new AxiosMockAdapter(axios);
  });

  afterEach(() => {
    axiosMock.reset();
  });

  describe('UI components', () => {
    beforeEach(() => {
      setWindowLocation(locationSearch);
      mountComponent();
      jest.runOnlyPendingTimers();
      return waitForPromises();
    });

    it('renders IssuableList component', () => {
      expect(findIssuableList().props()).toMatchObject({
        currentTab: IssuableStates.Opened,
        hasNextPage: true,
        hasPreviousPage: false,
        hasScopedLabelsFeature: defaultProvide.hasScopedLabelsFeature,
        initialSortBy: CREATED_DESC,
        issuables: issuesQueryResponse.data.issues.nodes,
        issuablesLoading: false,
        namespace: 'dashboard',
        recentSearchesStorageKey: 'issues',
        searchInputPlaceholder: i18n.searchPlaceholder,
        showPaginationControls: true,
        sortOptions: getSortOptions({
          hasBlockedIssuesFeature: defaultProvide.hasBlockedIssuesFeature,
          hasIssuableHealthStatusFeature: defaultProvide.hasIssuableHealthStatusFeature,
          hasIssueWeightsFeature: defaultProvide.hasIssueWeightsFeature,
        }),
        tabCounts: {
          opened: 1,
          closed: 2,
          all: 3,
        },
        tabs: IssuesDashboardApp.IssuableListTabs,
        urlParams: {
          sort: urlSortParams[CREATED_DESC],
          state: IssuableStates.Opened,
        },
        useKeysetPagination: true,
      });
    });

    it('renders RSS button link', () => {
      expect(findRssButton().attributes('href')).toBe(defaultProvide.rssPath);
    });

    it('renders calendar button link', () => {
      expect(findCalendarButton().attributes('href')).toBe(defaultProvide.calendarPath);
    });

    it('renders issue time information', () => {
      expect(findIssueCardTimeInfo().exists()).toBe(true);
    });

    it('renders issue statistics', () => {
      expect(findIssueCardStatistics().exists()).toBe(true);
    });
  });

  describe('fetching issues', () => {
    describe('with a search query', () => {
      describe('when there are issues returned', () => {
        beforeEach(() => {
          setWindowLocation(locationSearch);
          mountComponent();
          jest.runOnlyPendingTimers();
          return waitForPromises();
        });

        it('renders the issues', () => {
          expect(findIssuableList().props('issuables')).toEqual(
            defaultQueryResponse.data.issues.nodes,
          );
        });

        it('does not render empty state', () => {
          expect(findEmptyState().exists()).toBe(false);
        });
      });

      describe('when there are no issues returned', () => {
        beforeEach(() => {
          setWindowLocation(locationSearch);
          mountComponent({
            issuesQueryHandler: jest.fn().mockResolvedValue(emptyIssuesQueryResponse),
          });
          return waitForPromises();
        });

        it('renders no issues', () => {
          expect(findIssuableList().props('issuables')).toEqual([]);
        });

        it('renders empty state', () => {
          expect(findEmptyState().props()).toMatchObject({
            description: i18n.noSearchResultsDescription,
            svgPath: defaultProvide.emptyStateWithFilterSvgPath,
            title: i18n.noSearchResultsTitle,
          });
        });
      });
    });

    describe('with no search query', () => {
      let issuesQueryHandler;

      beforeEach(() => {
        issuesQueryHandler = jest.fn().mockResolvedValue(defaultQueryResponse);
        mountComponent({ issuesQueryHandler });
        return waitForPromises();
      });

      it('does not call issues query', () => {
        expect(issuesQueryHandler).not.toHaveBeenCalled();
      });

      it('renders empty state', () => {
        expect(findEmptyState().props()).toMatchObject({
          description: null,
          svgPath: defaultProvide.emptyStateWithoutFilterSvgPath,
          title: i18n.noSearchNoFilterTitle,
        });
      });
    });
  });

  describe('initial url params', () => {
    describe('search', () => {
      it('is set from the url params', () => {
        setWindowLocation(locationSearch);
        mountComponent();

        expect(findIssuableList().props('urlParams')).toMatchObject({ search: 'find issues' });
      });
    });

    describe('sort', () => {
      describe('when initial sort value uses old enum values', () => {
        const oldEnumSortValues = Object.values(urlSortParams);

        it.each(oldEnumSortValues)('initial sort is set with value %s', (sort) => {
          mountComponent({ provide: { initialSort: sort } });

          expect(findIssuableList().props('initialSortBy')).toBe(getSortKey(sort));
        });
      });

      describe('when initial sort value uses new GraphQL enum values', () => {
        const graphQLEnumSortValues = Object.keys(urlSortParams);

        it.each(graphQLEnumSortValues)('initial sort is set with value %s', (sort) => {
          mountComponent({ provide: { initialSort: sort.toLowerCase() } });

          expect(findIssuableList().props('initialSortBy')).toBe(sort);
        });
      });

      describe('when initial sort value is invalid', () => {
        it.each(['', 'asdf', null, undefined])(
          'initial sort is set to value CREATED_DESC',
          (sort) => {
            mountComponent({ provide: { initialSort: sort } });

            expect(findIssuableList().props('initialSortBy')).toBe(CREATED_DESC);
          },
        );
      });
    });

    describe('state', () => {
      it('is set from the url params', () => {
        const initialState = IssuableStates.All;
        setWindowLocation(`?state=${initialState}`);
        mountComponent();

        expect(findIssuableList().props('currentTab')).toBe(initialState);
      });
    });

    describe('filter tokens', () => {
      it('is set from the url params', () => {
        setWindowLocation(locationSearch);
        mountComponent();

        expect(findIssuableList().props('initialFilterValue')).toEqual(filteredTokens);
      });
    });
  });

  describe('errors', () => {
    describe.each`
      error                      | mountOption                   | message
      ${'fetching issues'}       | ${'issuesQueryHandler'}       | ${i18n.errorFetchingIssues}
      ${'fetching issue counts'} | ${'issuesCountsQueryHandler'} | ${i18n.errorFetchingCounts}
    `('when there is an error $error', ({ mountOption, message }) => {
      beforeEach(() => {
        setWindowLocation(locationSearch);
        mountComponent({ [mountOption]: jest.fn().mockRejectedValue(new Error('ERROR')) });
        jest.runOnlyPendingTimers();
        return waitForPromises();
      });

      it('shows an error message', () => {
        expect(findIssuableList().props('error')).toBe(message);
        expect(Sentry.captureException).toHaveBeenCalledWith(new Error('ERROR'));
      });
    });

    it('clears error message when "dismiss-alert" event is emitted from IssuableList', async () => {
      mountComponent({ issuesQueryHandler: jest.fn().mockRejectedValue(new Error()) });

      findIssuableList().vm.$emit('dismiss-alert');
      await nextTick();

      expect(findIssuableList().props('error')).toBeNull();
    });
  });

  describe('tokens', () => {
    const mockCurrentUser = {
      id: 1,
      name: 'Administrator',
      username: 'root',
      avatar_url: 'avatar/url',
    };
    const originalGon = window.gon;

    beforeEach(() => {
      window.gon = {
        ...originalGon,
        current_user_id: mockCurrentUser.id,
        current_user_fullname: mockCurrentUser.name,
        current_username: mockCurrentUser.username,
        current_user_avatar_url: mockCurrentUser.avatar_url,
      };
      mountComponent();
    });

    afterEach(() => {
      window.gon = originalGon;
    });

    it('renders all tokens alphabetically', () => {
      const preloadedUsers = [{ ...mockCurrentUser, id: mockCurrentUser.id }];

      expect(findIssuableList().props('searchTokens')).toMatchObject([
        { type: TOKEN_TYPE_ASSIGNEE, preloadedUsers },
        { type: TOKEN_TYPE_AUTHOR, preloadedUsers },
        { type: TOKEN_TYPE_CONFIDENTIAL },
        { type: TOKEN_TYPE_LABEL },
        { type: TOKEN_TYPE_MILESTONE },
        { type: TOKEN_TYPE_MY_REACTION },
        { type: TOKEN_TYPE_SEARCH_WITHIN },
        { type: TOKEN_TYPE_TYPE },
      ]);
    });
  });

  describe('events', () => {
    describe('when "click-tab" event is emitted by IssuableList', () => {
      beforeEach(() => {
        mountComponent();

        findIssuableList().vm.$emit('click-tab', IssuableStates.Closed);
      });

      it('updates ui to the new tab', () => {
        expect(findIssuableList().props('currentTab')).toBe(IssuableStates.Closed);
      });

      it('updates url to the new tab', () => {
        expect(findIssuableList().props('urlParams')).toMatchObject({
          state: IssuableStates.Closed,
        });
      });
    });

    describe.each(['next-page', 'previous-page'])(
      'when "%s" event is emitted by IssuableList',
      (event) => {
        beforeEach(() => {
          mountComponent();

          findIssuableList().vm.$emit(event);
        });

        it('scrolls to the top', () => {
          expect(scrollUp).toHaveBeenCalled();
        });
      },
    );

    describe('when "sort" event is emitted by IssuableList', () => {
      it.each(Object.keys(urlSortParams))(
        'updates to the new sort when payload is `%s`',
        async (sortKey) => {
          // Ensure initial sort key is different so we can trigger an update when emitting a sort key
          if (sortKey === CREATED_DESC) {
            mountComponent({ provide: { initialSort: UPDATED_DESC } });
          } else {
            mountComponent();
          }

          findIssuableList().vm.$emit('sort', sortKey);
          await nextTick();

          expect(findIssuableList().props('urlParams')).toMatchObject({
            sort: urlSortParams[sortKey],
          });
        },
      );

      describe('when user is signed in', () => {
        it('calls mutation to save sort preference', () => {
          const mutationMock = jest.fn().mockResolvedValue(setSortPreferenceMutationResponse);
          mountComponent({ sortPreferenceMutationHandler: mutationMock });

          findIssuableList().vm.$emit('sort', UPDATED_DESC);

          expect(mutationMock).toHaveBeenCalledWith({ input: { issuesSort: UPDATED_DESC } });
        });

        it('captures error when mutation response has errors', async () => {
          const mutationMock = jest
            .fn()
            .mockResolvedValue(setSortPreferenceMutationResponseWithErrors);
          mountComponent({ sortPreferenceMutationHandler: mutationMock });

          findIssuableList().vm.$emit('sort', UPDATED_DESC);
          await waitForPromises();

          expect(Sentry.captureException).toHaveBeenCalledWith(new Error('oh no!'));
        });
      });

      describe('when user is signed out', () => {
        it('does not call mutation to save sort preference', () => {
          const mutationMock = jest.fn().mockResolvedValue(setSortPreferenceMutationResponse);
          mountComponent({
            provide: { isSignedIn: false },
            sortPreferenceMutationHandler: mutationMock,
          });

          findIssuableList().vm.$emit('sort', CREATED_DESC);

          expect(mutationMock).not.toHaveBeenCalled();
        });
      });
    });
  });
});
