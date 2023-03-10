<script>
import { GlSkeletonLoader } from '@gitlab/ui';
import { s__ } from '~/locale';
import SystemNote from '~/work_items/components/notes/system_note.vue';
import ActivityFilter from '~/work_items/components/notes/activity_filter.vue';
import { i18n, DEFAULT_PAGE_SIZE_NOTES } from '~/work_items/constants';
import { ASC, DESC } from '~/notes/constants';
import { getWorkItemNotesQuery } from '~/work_items/utils';
import WorkItemDiscussion from '~/work_items/components/notes/work_item_discussion.vue';
import WorkItemCommentForm from './work_item_comment_form.vue';

export default {
  i18n: {
    ACTIVITY_LABEL: s__('WorkItem|Activity'),
  },
  loader: {
    repeat: 10,
    width: 1000,
    height: 40,
  },
  components: {
    GlSkeletonLoader,
    ActivityFilter,
    SystemNote,
    WorkItemCommentForm,
    WorkItemDiscussion,
  },
  props: {
    workItemId: {
      type: String,
      required: true,
    },
    queryVariables: {
      type: Object,
      required: true,
    },
    fullPath: {
      type: String,
      required: true,
    },
    workItemType: {
      type: String,
      required: true,
    },
    fetchByIid: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      notesArray: [],
      isLoadingMore: false,
      perPage: DEFAULT_PAGE_SIZE_NOTES,
      sortOrder: ASC,
      changeNotesSortOrderAfterLoading: false,
    };
  },
  computed: {
    initialLoading() {
      return this.$apollo.queries.workItemNotes.loading && !this.isLoadingMore;
    },
    pageInfo() {
      return this.workItemNotes?.pageInfo;
    },
    avatarUrl() {
      return window.gon.current_user_avatar_url;
    },
    hasNextPage() {
      return this.pageInfo?.hasNextPage;
    },
    showInitialLoader() {
      return this.initialLoading || this.changeNotesSortOrderAfterLoading;
    },
    showTimeline() {
      return !this.changeNotesSortOrderAfterLoading;
    },
    showLoadingMoreSkeleton() {
      return this.isLoadingMore && !this.changeNotesSortOrderAfterLoading;
    },
    disableActivityFilter() {
      return this.initialLoading || this.isLoadingMore;
    },
    formAtTop() {
      return this.sortOrder === DESC;
    },
    workItemCommentFormProps() {
      return {
        queryVariables: this.queryVariables,
        fullPath: this.fullPath,
        workItemId: this.workItemId,
        fetchByIid: this.fetchByIid,
        workItemType: this.workItemType,
        sortOrder: this.sortOrder,
      };
    },
  },
  apollo: {
    workItemNotes: {
      query() {
        return getWorkItemNotesQuery(this.fetchByIid);
      },
      context: {
        isSingleRequest: true,
      },
      variables() {
        return {
          ...this.queryVariables,
          after: this.after,
          pageSize: DEFAULT_PAGE_SIZE_NOTES,
        };
      },
      update(data) {
        const workItemWidgets = this.fetchByIid
          ? data.workspace?.workItems?.nodes[0]?.widgets
          : data.workItem?.widgets;
        const discussionNodes =
          workItemWidgets.find((widget) => widget.type === 'NOTES')?.discussions || [];
        this.notesArray = discussionNodes?.nodes || [];
        this.updateSortingOrderIfApplicable();
        return discussionNodes;
      },
      skip() {
        return !this.queryVariables.id && !this.queryVariables.iid;
      },
      error() {
        this.$emit('error', i18n.fetchError);
      },
      result() {
        if (this.hasNextPage) {
          this.fetchMoreNotes();
        }
      },
    },
  },
  methods: {
    getDiscussionKey(discussion) {
      // discussion key is important like this since after first comment changes
      const discussionId = discussion.notes.nodes[0].id;
      return discussionId.split('/')[discussionId.split('/').length - 1];
    },
    isSystemNote(note) {
      return note.notes.nodes[0].system;
    },
    updateSortingOrderIfApplicable() {
      // when the sort order is DESC in local storage and there is only a single page, call
      // changeSortOrder manually
      if (
        this.changeNotesSortOrderAfterLoading &&
        this.perPage === DEFAULT_PAGE_SIZE_NOTES &&
        !this.hasNextPage
      ) {
        this.changeNotesSortOrder(DESC);
      }
    },
    updateInitialSortedOrder(direction) {
      this.sortOrder = direction;
      // when the direction is reverse , we need to load all since the sorting is on the frontend
      if (direction === DESC) {
        this.changeNotesSortOrderAfterLoading = true;
      }
    },
    changeNotesSortOrder(direction) {
      this.sortOrder = direction;
      this.notesArray = [...this.notesArray].reverse();
      this.changeNotesSortOrderAfterLoading = false;
    },
    async fetchMoreNotes() {
      this.isLoadingMore = true;
      // copied from discussions batch logic - every fetchMore call has a higher
      // amount of page size than the previous one with the limit being 100
      this.perPage = Math.min(Math.round(this.perPage * 1.5), 100);
      await this.$apollo.queries.workItemNotes
        .fetchMore({
          variables: {
            ...this.queryVariables,
            pageSize: this.perPage,
            after: this.pageInfo?.endCursor,
          },
        })
        .catch((error) => this.$emit('error', error.message));
      this.isLoadingMore = false;
      if (this.changeNotesSortOrderAfterLoading && !this.hasNextPage) {
        this.changeNotesSortOrder(this.sortOrder);
      }
    },
  },
};
</script>

<template>
  <div class="gl-border-t gl-mt-5 work-item-notes">
    <div class="gl-display-flex gl-justify-content-space-between gl-flex-wrap">
      <label class="gl-mb-0">{{ $options.i18n.ACTIVITY_LABEL }}</label>
      <activity-filter
        class="gl-min-h-5 gl-pb-3"
        :loading="disableActivityFilter"
        :sort-order="sortOrder"
        :work-item-type="workItemType"
        @changeSortOrder="changeNotesSortOrder"
        @updateSavedSortOrder="updateInitialSortedOrder"
      />
    </div>
    <div v-if="showInitialLoader" class="gl-mt-5">
      <gl-skeleton-loader
        v-for="index in $options.loader.repeat"
        :key="index"
        :width="$options.loader.width"
        :height="$options.loader.height"
        preserve-aspect-ratio="xMinYMax meet"
      >
        <circle cx="20" cy="20" r="16" />
        <rect width="500" x="45" y="15" height="10" rx="4" />
      </gl-skeleton-loader>
    </div>
    <div v-else class="issuable-discussion gl-mb-5 gl-clearfix!">
      <template v-if="showTimeline">
        <ul class="notes main-notes-list timeline gl-clearfix!">
          <work-item-comment-form
            v-if="formAtTop"
            v-bind="workItemCommentFormProps"
            @error="$emit('error', $event)"
          />

          <template v-for="discussion in notesArray">
            <system-note
              v-if="isSystemNote(discussion)"
              :key="discussion.notes.nodes[0].id"
              :note="discussion.notes.nodes[0]"
            />
            <template v-else>
              <work-item-discussion
                :key="getDiscussionKey(discussion)"
                :discussion="discussion.notes.nodes"
                :query-variables="queryVariables"
                :full-path="fullPath"
                :work-item-id="workItemId"
                :fetch-by-iid="fetchByIid"
                :work-item-type="workItemType"
              />
            </template>
          </template>

          <work-item-comment-form
            v-if="!formAtTop"
            v-bind="workItemCommentFormProps"
            @error="$emit('error', $event)"
          />
        </ul>
      </template>

      <template v-if="showLoadingMoreSkeleton">
        <gl-skeleton-loader
          v-for="index in $options.loader.repeat"
          :key="index"
          :width="$options.loader.width"
          :height="$options.loader.height"
          preserve-aspect-ratio="xMinYMax meet"
        >
          <circle cx="20" cy="20" r="16" />
          <rect width="500" x="45" y="15" height="10" rx="4" />
        </gl-skeleton-loader>
      </template>
    </div>
  </div>
</template>
