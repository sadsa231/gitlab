import { GlSkeletonLoader } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import SystemNote from '~/work_items/components/notes/system_note.vue';
import WorkItemNotes from '~/work_items/components/work_item_notes.vue';
import WorkItemDiscussion from '~/work_items/components/notes/work_item_discussion.vue';
import WorkItemCommentForm from '~/work_items/components/work_item_comment_form.vue';
import ActivityFilter from '~/work_items/components/notes/activity_filter.vue';
import workItemNotesQuery from '~/work_items/graphql/work_item_notes.query.graphql';
import workItemNotesByIidQuery from '~/work_items/graphql/work_item_notes_by_iid.query.graphql';
import { DEFAULT_PAGE_SIZE_NOTES, WIDGET_TYPE_NOTES } from '~/work_items/constants';
import { ASC, DESC } from '~/notes/constants';
import {
  mockWorkItemNotesResponse,
  workItemQueryResponse,
  mockWorkItemNotesByIidResponse,
  mockMoreWorkItemNotesResponse,
  mockWorkItemNotesResponseWithComments,
} from '../mock_data';

const mockWorkItemId = workItemQueryResponse.data.workItem.id;
const mockNotesWidgetResponse = mockWorkItemNotesResponse.data.workItem.widgets.find(
  (widget) => widget.type === WIDGET_TYPE_NOTES,
);

const mockNotesByIidWidgetResponse = mockWorkItemNotesByIidResponse.data.workspace.workItems.nodes[0].widgets.find(
  (widget) => widget.type === WIDGET_TYPE_NOTES,
);

const mockMoreNotesWidgetResponse = mockMoreWorkItemNotesResponse.data.workItem.widgets.find(
  (widget) => widget.type === WIDGET_TYPE_NOTES,
);

const mockWorkItemNotesWidgetResponseWithComments = mockWorkItemNotesResponseWithComments.data.workItem.widgets.find(
  (widget) => widget.type === WIDGET_TYPE_NOTES,
);

const firstSystemNodeId = mockNotesWidgetResponse.discussions.nodes[0].notes.nodes[0].id;

const mockDiscussions = mockWorkItemNotesWidgetResponseWithComments.discussions.nodes;

describe('WorkItemNotes component', () => {
  let wrapper;

  Vue.use(VueApollo);

  const findAllSystemNotes = () => wrapper.findAllComponents(SystemNote);
  const findAllListItems = () => wrapper.findAll('ul.timeline > *');
  const findActivityLabel = () => wrapper.find('label');
  const findWorkItemCommentForm = () => wrapper.findComponent(WorkItemCommentForm);
  const findSkeletonLoader = () => wrapper.findComponent(GlSkeletonLoader);
  const findSortingFilter = () => wrapper.findComponent(ActivityFilter);
  const findSystemNoteAtIndex = (index) => findAllSystemNotes().at(index);
  const findAllWorkItemCommentNotes = () => wrapper.findAllComponents(WorkItemDiscussion);
  const findWorkItemCommentNoteAtIndex = (index) => findAllWorkItemCommentNotes().at(index);
  const workItemNotesQueryHandler = jest.fn().mockResolvedValue(mockWorkItemNotesResponse);
  const workItemNotesByIidQueryHandler = jest
    .fn()
    .mockResolvedValue(mockWorkItemNotesByIidResponse);
  const workItemMoreNotesQueryHandler = jest.fn().mockResolvedValue(mockMoreWorkItemNotesResponse);
  const workItemNotesWithCommentsQueryHandler = jest
    .fn()
    .mockResolvedValue(mockWorkItemNotesResponseWithComments);

  const createComponent = ({
    workItemId = mockWorkItemId,
    fetchByIid = false,
    defaultWorkItemNotesQueryHandler = workItemNotesQueryHandler,
  } = {}) => {
    wrapper = shallowMount(WorkItemNotes, {
      apolloProvider: createMockApollo([
        [workItemNotesQuery, defaultWorkItemNotesQueryHandler],
        [workItemNotesByIidQuery, workItemNotesByIidQueryHandler],
      ]),
      propsData: {
        workItemId,
        queryVariables: {
          id: workItemId,
        },
        fullPath: 'test-path',
        fetchByIid,
        workItemType: 'task',
      },
      provide: {
        glFeatures: {
          useIidInWorkItemsPath: fetchByIid,
        },
      },
    });
  };

  beforeEach(async () => {
    createComponent();
  });

  it('renders activity label', () => {
    expect(findActivityLabel().exists()).toBe(true);
  });

  it('passes correct props to comment form component', async () => {
    createComponent({
      workItemId: mockWorkItemId,
      fetchByIid: false,
      defaultWorkItemNotesQueryHandler: workItemNotesByIidQueryHandler,
    });
    await waitForPromises();

    expect(findWorkItemCommentForm().props('fetchByIid')).toEqual(false);
  });

  describe('when notes are loading', () => {
    it('renders skeleton loader', () => {
      expect(findSkeletonLoader().exists()).toBe(true);
    });

    it('does not render system notes', () => {
      expect(findAllSystemNotes().exists()).toBe(false);
    });
  });

  describe('when notes have been loaded', () => {
    it('does not render skeleton loader', () => {
      expect(findSkeletonLoader().exists()).toBe(true);
    });

    it('renders system notes to the length of the response', async () => {
      await waitForPromises();
      expect(findAllSystemNotes()).toHaveLength(mockNotesWidgetResponse.discussions.nodes.length);
    });
  });

  describe('when the notes are fetched by `iid`', () => {
    beforeEach(async () => {
      createComponent({ workItemId: mockWorkItemId, fetchByIid: true });
      await waitForPromises();
    });

    it('renders the notes list to the length of the response', () => {
      expect(workItemNotesByIidQueryHandler).toHaveBeenCalled();
      expect(findAllSystemNotes()).toHaveLength(
        mockNotesByIidWidgetResponse.discussions.nodes.length,
      );
    });

    it('passes correct props to comment form component', () => {
      expect(findWorkItemCommentForm().props('fetchByIid')).toEqual(true);
    });
  });

  describe('Pagination', () => {
    describe('When there is no next page', () => {
      it('fetch more notes is not called', async () => {
        createComponent();
        await nextTick();
        expect(workItemMoreNotesQueryHandler).not.toHaveBeenCalled();
      });
    });

    describe('when there is next page', () => {
      beforeEach(async () => {
        createComponent({ defaultWorkItemNotesQueryHandler: workItemMoreNotesQueryHandler });
        await waitForPromises();
      });

      it('fetch more notes should be called', async () => {
        expect(workItemMoreNotesQueryHandler).toHaveBeenCalledWith({
          pageSize: DEFAULT_PAGE_SIZE_NOTES,
          id: 'gid://gitlab/WorkItem/1',
        });

        await nextTick();

        expect(workItemMoreNotesQueryHandler).toHaveBeenCalledWith({
          pageSize: 45,
          id: 'gid://gitlab/WorkItem/1',
          after: mockMoreNotesWidgetResponse.discussions.pageInfo.endCursor,
        });
      });
    });
  });

  describe('Sorting', () => {
    beforeEach(async () => {
      createComponent();
      await waitForPromises();
    });

    it('filter exists', () => {
      expect(findSortingFilter().exists()).toBe(true);
    });

    it('sorts the list when the `changeSortOrder` event is emitted', async () => {
      expect(findSystemNoteAtIndex(0).props('note').id).toEqual(firstSystemNodeId);

      await findSortingFilter().vm.$emit('changeSortOrder', DESC);

      expect(findSystemNoteAtIndex(0).props('note').id).not.toEqual(firstSystemNodeId);
    });

    it('puts form at start of list in when sorting by newest first', async () => {
      await findSortingFilter().vm.$emit('changeSortOrder', DESC);

      expect(findAllListItems().at(0).is(WorkItemCommentForm)).toEqual(true);
    });

    it('puts form at end of list in when sorting by oldest first', async () => {
      await findSortingFilter().vm.$emit('changeSortOrder', ASC);

      expect(findAllListItems().at(-1).is(WorkItemCommentForm)).toEqual(true);
    });
  });

  describe('Activity comments', () => {
    beforeEach(async () => {
      createComponent({
        defaultWorkItemNotesQueryHandler: workItemNotesWithCommentsQueryHandler,
      });
      await waitForPromises();
    });

    it('should not have any system notes', () => {
      expect(workItemNotesWithCommentsQueryHandler).toHaveBeenCalled();
      expect(findAllSystemNotes()).toHaveLength(0);
    });

    it('should have work item notes', () => {
      expect(workItemNotesWithCommentsQueryHandler).toHaveBeenCalled();
      expect(findAllWorkItemCommentNotes()).toHaveLength(mockDiscussions.length);
    });

    it('should pass all the correct props to work item comment note', () => {
      const commentIndex = 0;
      const firstCommentNote = findWorkItemCommentNoteAtIndex(commentIndex);

      expect(firstCommentNote.props('discussion')).toEqual(
        mockDiscussions[commentIndex].notes.nodes,
      );
    });
  });
});
