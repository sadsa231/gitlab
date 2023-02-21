import MockAdapter from 'axios-mock-adapter';
import testAction from 'helpers/vuex_action_helper';
import Api from '~/api';
import { createAlert } from '~/flash';
import * as logger from '~/lib/logger';
import axios from '~/lib/utils/axios_utils';
import * as urlUtils from '~/lib/utils/url_utility';
import * as actions from '~/search/store/actions';
import {
  GROUPS_LOCAL_STORAGE_KEY,
  PROJECTS_LOCAL_STORAGE_KEY,
  SIDEBAR_PARAMS,
} from '~/search/store/constants';
import * as types from '~/search/store/mutation_types';
import createState from '~/search/store/state';
import * as storeUtils from '~/search/store/utils';
import {
  MOCK_QUERY,
  MOCK_GROUPS,
  MOCK_PROJECT,
  MOCK_PROJECTS,
  MOCK_GROUP,
  FRESH_STORED_DATA,
  MOCK_FRESH_DATA_RES,
  PRELOAD_EXPECTED_MUTATIONS,
  PROMISE_ALL_EXPECTED_MUTATIONS,
  MOCK_NAVIGATION_DATA,
  MOCK_NAVIGATION_ACTION_MUTATION,
  MOCK_ENDPOINT_RESPONSE,
  MOCK_RECEIVE_AGGREGATIONS_SUCCESS_MUTATION,
  MOCK_RECEIVE_AGGREGATIONS_ERROR_MUTATION,
  MOCK_AGGREGATIONS,
} from '../mock_data';

jest.mock('~/flash');
jest.mock('~/lib/utils/url_utility', () => ({
  setUrlParams: jest.fn(),
  joinPaths: jest.fn().mockReturnValue(''),
  visitUrl: jest.fn(),
}));
jest.mock('~/lib/logger', () => ({
  logError: jest.fn(),
}));

describe('Global Search Store Actions', () => {
  let mock;
  let state;

  const flashCallback = (callCount) => {
    expect(createAlert).toHaveBeenCalledTimes(callCount);
    createAlert.mockClear();
  };

  beforeEach(() => {
    state = createState({ query: MOCK_QUERY });
    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    state = null;
    mock.restore();
  });

  describe.each`
    action                   | axiosMock                                             | type         | expectedMutations                                                                                       | flashCallCount
    ${actions.fetchGroups}   | ${{ method: 'onGet', code: 200, res: MOCK_GROUPS }}   | ${'success'} | ${[{ type: types.REQUEST_GROUPS }, { type: types.RECEIVE_GROUPS_SUCCESS, payload: MOCK_GROUPS }]}       | ${0}
    ${actions.fetchGroups}   | ${{ method: 'onGet', code: 500, res: null }}          | ${'error'}   | ${[{ type: types.REQUEST_GROUPS }, { type: types.RECEIVE_GROUPS_ERROR }]}                               | ${1}
    ${actions.fetchProjects} | ${{ method: 'onGet', code: 200, res: MOCK_PROJECTS }} | ${'success'} | ${[{ type: types.REQUEST_PROJECTS }, { type: types.RECEIVE_PROJECTS_SUCCESS, payload: MOCK_PROJECTS }]} | ${0}
    ${actions.fetchProjects} | ${{ method: 'onGet', code: 500, res: null }}          | ${'error'}   | ${[{ type: types.REQUEST_PROJECTS }, { type: types.RECEIVE_PROJECTS_ERROR }]}                           | ${1}
  `(`axios calls`, ({ action, axiosMock, type, expectedMutations, flashCallCount }) => {
    describe(action.name, () => {
      describe(`on ${type}`, () => {
        beforeEach(() => {
          mock[axiosMock.method]().replyOnce(axiosMock.code, axiosMock.res);
        });
        it(`should dispatch the correct mutations`, () => {
          return testAction({ action, state, expectedMutations }).then(() =>
            flashCallback(flashCallCount),
          );
        });
      });
    });
  });

  describe.each`
    action                          | axiosMock                         | type         | expectedMutations                               | flashCallCount
    ${actions.loadFrequentGroups}   | ${{ method: 'onGet', code: 200 }} | ${'success'} | ${[PROMISE_ALL_EXPECTED_MUTATIONS.resGroups]}   | ${0}
    ${actions.loadFrequentGroups}   | ${{ method: 'onGet', code: 500 }} | ${'error'}   | ${[]}                                           | ${1}
    ${actions.loadFrequentProjects} | ${{ method: 'onGet', code: 200 }} | ${'success'} | ${[PROMISE_ALL_EXPECTED_MUTATIONS.resProjects]} | ${0}
    ${actions.loadFrequentProjects} | ${{ method: 'onGet', code: 500 }} | ${'error'}   | ${[]}                                           | ${1}
  `('Promise.all calls', ({ action, axiosMock, type, expectedMutations, flashCallCount }) => {
    describe(action.name, () => {
      describe(`on ${type}`, () => {
        beforeEach(() => {
          state.frequentItems = {
            [GROUPS_LOCAL_STORAGE_KEY]: FRESH_STORED_DATA,
            [PROJECTS_LOCAL_STORAGE_KEY]: FRESH_STORED_DATA,
          };

          mock[axiosMock.method]().reply(axiosMock.code, MOCK_FRESH_DATA_RES);
        });

        it(`should dispatch the correct mutations`, () => {
          return testAction({ action, state, expectedMutations }).then(() => {
            flashCallback(flashCallCount);
          });
        });
      });
    });
  });

  describe('getGroupsData', () => {
    const mockCommit = () => {};
    beforeEach(() => {
      jest.spyOn(Api, 'groups').mockResolvedValue(MOCK_GROUPS);
    });

    it('calls Api.groups with order_by set to similarity', () => {
      actions.fetchGroups({ commit: mockCommit }, 'test');

      expect(Api.groups).toHaveBeenCalledWith('test', { order_by: 'similarity' });
    });
  });

  describe('getProjectsData', () => {
    const mockCommit = () => {};
    beforeEach(() => {
      jest.spyOn(Api, 'groupProjects').mockResolvedValue(MOCK_PROJECTS);
      jest.spyOn(Api, 'projects').mockResolvedValue(MOCK_PROJECT);
    });

    describe('when groupId is set', () => {
      it('calls Api.groupProjects with expected parameters', () => {
        actions.fetchProjects({ commit: mockCommit, state }, undefined);
        expect(Api.groupProjects).toHaveBeenCalledWith(state.query.group_id, state.query.search, {
          order_by: 'similarity',
          include_subgroups: true,
          with_shared: false,
        });
        expect(Api.projects).not.toHaveBeenCalled();
      });
    });

    describe('when groupId is not set', () => {
      beforeEach(() => {
        state = createState({ query: { group_id: null } });
      });

      it('calls Api.projects', () => {
        actions.fetchProjects({ commit: mockCommit, state });
        expect(Api.groupProjects).not.toHaveBeenCalled();
        expect(Api.projects).toHaveBeenCalledWith(state.query.search, {
          order_by: 'similarity',
        });
      });
    });
  });

  describe.each`
    payload                                      | isDirty  | isDirtyMutation
    ${{ key: SIDEBAR_PARAMS[0], value: 'test' }} | ${false} | ${[{ type: types.SET_SIDEBAR_DIRTY, payload: false }]}
    ${{ key: SIDEBAR_PARAMS[0], value: 'test' }} | ${true}  | ${[{ type: types.SET_SIDEBAR_DIRTY, payload: true }]}
    ${{ key: SIDEBAR_PARAMS[1], value: 'test' }} | ${false} | ${[{ type: types.SET_SIDEBAR_DIRTY, payload: false }]}
    ${{ key: SIDEBAR_PARAMS[1], value: 'test' }} | ${true}  | ${[{ type: types.SET_SIDEBAR_DIRTY, payload: true }]}
    ${{ key: 'non-sidebar', value: 'test' }}     | ${false} | ${[]}
    ${{ key: 'non-sidebar', value: 'test' }}     | ${true}  | ${[]}
  `('setQuery', ({ payload, isDirty, isDirtyMutation }) => {
    describe(`when filter param is ${payload.key} and utils.isSidebarDirty returns ${isDirty}`, () => {
      const expectedMutations = [{ type: types.SET_QUERY, payload }].concat(isDirtyMutation);

      beforeEach(() => {
        storeUtils.isSidebarDirty = jest.fn().mockReturnValue(isDirty);
      });

      it(`should dispatch the correct mutations`, () => {
        return testAction({ action: actions.setQuery, payload, state, expectedMutations });
      });
    });
  });

  describe('applyQuery', () => {
    it('calls visitUrl and setParams with the state.query', () => {
      return testAction(actions.applyQuery, null, state, [], [], () => {
        expect(urlUtils.setUrlParams).toHaveBeenCalledWith({ ...state.query, page: null });
        expect(urlUtils.visitUrl).toHaveBeenCalled();
      });
    });
  });

  describe('resetQuery', () => {
    it('calls visitUrl and setParams with empty values', () => {
      return testAction(actions.resetQuery, null, state, [], [], () => {
        expect(urlUtils.setUrlParams).toHaveBeenCalledWith({
          ...state.query,
          page: null,
          state: null,
          confidential: null,
        });
        expect(urlUtils.visitUrl).toHaveBeenCalled();
      });
    });
  });

  describe('preloadStoredFrequentItems', () => {
    beforeEach(() => {
      storeUtils.loadDataFromLS = jest.fn().mockReturnValue(FRESH_STORED_DATA);
    });

    it('calls preloadStoredFrequentItems for both groups and projects and commits LOAD_FREQUENT_ITEMS', async () => {
      await testAction({
        action: actions.preloadStoredFrequentItems,
        state,
        expectedMutations: PRELOAD_EXPECTED_MUTATIONS,
      });

      expect(storeUtils.loadDataFromLS).toHaveBeenCalledTimes(2);
      expect(storeUtils.loadDataFromLS).toHaveBeenCalledWith(GROUPS_LOCAL_STORAGE_KEY);
      expect(storeUtils.loadDataFromLS).toHaveBeenCalledWith(PROJECTS_LOCAL_STORAGE_KEY);
    });
  });

  describe('setFrequentGroup', () => {
    beforeEach(() => {
      storeUtils.setFrequentItemToLS = jest.fn().mockReturnValue(FRESH_STORED_DATA);
    });

    it(`calls setFrequentItemToLS with ${GROUPS_LOCAL_STORAGE_KEY} and item data then commits LOAD_FREQUENT_ITEMS`, async () => {
      await testAction({
        action: actions.setFrequentGroup,
        expectedMutations: [
          {
            type: types.LOAD_FREQUENT_ITEMS,
            payload: { key: GROUPS_LOCAL_STORAGE_KEY, data: FRESH_STORED_DATA },
          },
        ],
        payload: MOCK_GROUP,
        state,
      });

      expect(storeUtils.setFrequentItemToLS).toHaveBeenCalledWith(
        GROUPS_LOCAL_STORAGE_KEY,
        state.frequentItems,
        MOCK_GROUP,
      );
    });
  });

  describe('setFrequentProject', () => {
    beforeEach(() => {
      storeUtils.setFrequentItemToLS = jest.fn().mockReturnValue(FRESH_STORED_DATA);
    });

    it(`calls setFrequentItemToLS with ${PROJECTS_LOCAL_STORAGE_KEY} and item data`, async () => {
      await testAction({
        action: actions.setFrequentProject,
        expectedMutations: [
          {
            type: types.LOAD_FREQUENT_ITEMS,
            payload: { key: PROJECTS_LOCAL_STORAGE_KEY, data: FRESH_STORED_DATA },
          },
        ],
        payload: MOCK_PROJECT,
        state,
      });

      expect(storeUtils.setFrequentItemToLS).toHaveBeenCalledWith(
        PROJECTS_LOCAL_STORAGE_KEY,
        state.frequentItems,
        MOCK_PROJECT,
      );
    });
  });

  describe.each`
    action                       | axiosMock                         | type         | scope         | expectedMutations                    | errorLogs
    ${actions.fetchSidebarCount} | ${{ method: 'onGet', code: 200 }} | ${'success'} | ${'issues'}   | ${[MOCK_NAVIGATION_ACTION_MUTATION]} | ${0}
    ${actions.fetchSidebarCount} | ${{ method: null, code: 0 }}      | ${'success'} | ${'projects'} | ${[]}                                | ${0}
    ${actions.fetchSidebarCount} | ${{ method: 'onGet', code: 500 }} | ${'error'}   | ${'issues'}   | ${[]}                                | ${1}
  `('fetchSidebarCount', ({ action, axiosMock, type, expectedMutations, scope, errorLogs }) => {
    describe(`on ${type}`, () => {
      beforeEach(() => {
        state.navigation = MOCK_NAVIGATION_DATA;
        state.urlQuery = {
          scope,
        };

        if (axiosMock.method) {
          mock[axiosMock.method]().reply(axiosMock.code, MOCK_ENDPOINT_RESPONSE);
        }
      });

      it(`should ${expectedMutations.length === 0 ? 'NOT ' : ''}dispatch ${
        expectedMutations.length === 0 ? '' : 'the correct '
      }mutations for ${scope}`, () => {
        return testAction({ action, state, expectedMutations }).then(() => {
          expect(logger.logError).toHaveBeenCalledTimes(errorLogs);
        });
      });
    });
  });

  describe.each`
    action                              | axiosMock                         | type         | expectedMutations                             | errorLogs
    ${actions.fetchLanguageAggregation} | ${{ method: 'onGet', code: 200 }} | ${'success'} | ${MOCK_RECEIVE_AGGREGATIONS_SUCCESS_MUTATION} | ${0}
    ${actions.fetchLanguageAggregation} | ${{ method: 'onPut', code: 0 }}   | ${'error'}   | ${MOCK_RECEIVE_AGGREGATIONS_ERROR_MUTATION}   | ${1}
    ${actions.fetchLanguageAggregation} | ${{ method: 'onGet', code: 500 }} | ${'error'}   | ${MOCK_RECEIVE_AGGREGATIONS_ERROR_MUTATION}   | ${1}
  `('fetchLanguageAggregation', ({ action, axiosMock, type, expectedMutations, errorLogs }) => {
    describe(`on ${type}`, () => {
      beforeEach(() => {
        if (axiosMock.method) {
          mock[axiosMock.method]().reply(
            axiosMock.code,
            axiosMock.code === 200 ? MOCK_AGGREGATIONS : [],
          );
        }
      });

      it(`should ${type === 'error' ? 'NOT ' : ''}dispatch ${
        type === 'error' ? '' : 'the correct '
      }mutations`, () => {
        return testAction({ action, state, expectedMutations }).then(() => {
          expect(logger.logError).toHaveBeenCalledTimes(errorLogs);
        });
      });
    });
  });
});
