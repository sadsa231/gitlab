import { orderBy } from 'lodash';
import { shallowMount } from '@vue/test-utils';
import BoardFilteredSearch from 'ee_else_ce/boards/components/board_filtered_search.vue';
import IssueBoardFilteredSpec from '~/boards/components/issue_board_filtered_search.vue';
import issueBoardFilters from '~/boards/issue_board_filters';
import { mockTokens } from '../mock_data';

jest.mock('~/boards/issue_board_filters');

describe('IssueBoardFilter', () => {
  let wrapper;

  const findBoardsFilteredSearch = () => wrapper.findComponent(BoardFilteredSearch);

  const createComponent = ({ isSignedIn = false } = {}) => {
    wrapper = shallowMount(IssueBoardFilteredSpec, {
      provide: {
        isSignedIn,
        releasesFetchPath: '/releases',
        fullPath: 'gitlab-org',
        isGroupBoard: true,
      },
    });
  };

  let fetchUsersSpy;
  let fetchLabelsSpy;
  beforeEach(() => {
    fetchUsersSpy = jest.fn();
    fetchLabelsSpy = jest.fn();

    issueBoardFilters.mockReturnValue({
      fetchUsers: fetchUsersSpy,
      fetchLabels: fetchLabelsSpy,
    });
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('default', () => {
    beforeEach(() => {
      createComponent();
    });

    it('finds BoardFilteredSearch', () => {
      expect(findBoardsFilteredSearch().exists()).toBe(true);
    });

    it.each`
      isSignedIn
      ${true}
      ${false}
    `(
      'passes the correct tokens to BoardFilteredSearch when user sign in is $isSignedIn',
      ({ isSignedIn }) => {
        createComponent({ isSignedIn });

        const tokens = mockTokens(
          fetchLabelsSpy,
          fetchUsersSpy,
          wrapper.vm.fetchMilestones,
          isSignedIn,
        );

        expect(findBoardsFilteredSearch().props('tokens')).toEqual(orderBy(tokens, ['title']));
      },
    );
  });
});
