<script>
import { isEmpty } from 'lodash';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { TYPE_WORK_ITEM } from '~/graphql_shared/constants';
import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';
import { parseBoolean } from '~/lib/utils/common_utils';
import { getParameterByName } from '~/lib/utils/url_utility';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';

import {
  FORM_TYPES,
  WIDGET_TYPE_HIERARCHY,
  WORK_ITEMS_TREE_TEXT_MAP,
  WORK_ITEM_TYPE_ENUM_OBJECTIVE,
  WORK_ITEM_TYPE_ENUM_KEY_RESULT,
  WORK_ITEM_TYPE_VALUE_OBJECTIVE,
} from '../../constants';
import workItemQuery from '../../graphql/work_item.query.graphql';
import workItemByIidQuery from '../../graphql/work_item_by_iid.query.graphql';
import WidgetWrapper from '../widget_wrapper.vue';
import OkrActionsSplitButton from './okr_actions_split_button.vue';
import WorkItemLinksForm from './work_item_links_form.vue';
import WorkItemLinkChild from './work_item_link_child.vue';

export default {
  FORM_TYPES,
  WORK_ITEMS_TREE_TEXT_MAP,
  WORK_ITEM_TYPE_ENUM_OBJECTIVE,
  WORK_ITEM_TYPE_ENUM_KEY_RESULT,
  components: {
    OkrActionsSplitButton,
    WidgetWrapper,
    WorkItemLinksForm,
    WorkItemLinkChild,
  },
  mixins: [glFeatureFlagMixin()],
  props: {
    workItemType: {
      type: String,
      required: true,
    },
    parentWorkItemType: {
      type: String,
      required: false,
      default: '',
    },
    workItemId: {
      type: String,
      required: true,
    },
    confidential: {
      type: Boolean,
      required: false,
      default: false,
    },
    children: {
      type: Array,
      required: false,
      default: () => [],
    },
    canUpdate: {
      type: Boolean,
      required: false,
      default: false,
    },
    projectPath: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      isShownAddForm: false,
      formType: null,
      childType: null,
      prefetchedWorkItem: null,
    };
  },
  computed: {
    fetchByIid() {
      return this.glFeatures.useIidInWorkItemsPath && parseBoolean(getParameterByName('iid_path'));
    },
    childrenIds() {
      return this.children.map((c) => c.id);
    },
    hasIndirectChildren() {
      return this.children
        .map(
          (child) => child.widgets?.find((widget) => widget.type === WIDGET_TYPE_HIERARCHY) || {},
        )
        .some((hierarchy) => hierarchy.hasChildren);
    },
    childUrlParams() {
      const params = {};
      if (this.fetchByIid) {
        const iid = getParameterByName('work_item_iid');
        if (iid) {
          params.iid = iid;
        }
      } else {
        const workItemId = getParameterByName('work_item_id');
        if (workItemId) {
          params.id = convertToGraphQLId(TYPE_WORK_ITEM, workItemId);
        }
      }
      return params;
    },
  },
  mounted() {
    if (!isEmpty(this.childUrlParams)) {
      this.addWorkItemQuery(this.childUrlParams);
    }
  },
  methods: {
    showAddForm(formType, childType) {
      this.$refs.wrapper.show();
      this.isShownAddForm = true;
      this.formType = formType;
      this.childType = childType;
      this.$nextTick(() => {
        this.$refs.wiLinksForm.$refs.wiTitleInput?.$el.focus();
      });
    },
    hideAddForm() {
      this.isShownAddForm = false;
    },
    addWorkItemQuery({ id, iid }) {
      const variables = this.fetchByIid
        ? {
            fullPath: this.projectPath,
            iid,
          }
        : {
            id,
          };
      this.$apollo.addSmartQuery('prefetchedWorkItem', {
        query() {
          return this.fetchByIid ? workItemByIidQuery : workItemQuery;
        },
        variables,
        update(data) {
          return this.fetchByIid ? data.workspace.workItems.nodes[0] : data.workItem;
        },
        context: {
          isSingleRequest: true,
        },
      });
    },
    prefetchWorkItem({ id, iid }) {
      if (this.workItemType !== WORK_ITEM_TYPE_VALUE_OBJECTIVE) {
        this.prefetch = setTimeout(
          () => this.addWorkItemQuery({ id, iid }),
          DEFAULT_DEBOUNCE_AND_THROTTLE_MS,
        );
      }
    },
    clearPrefetching() {
      if (this.prefetch) {
        clearTimeout(this.prefetch);
      }
    },
  },
};
</script>

<template>
  <widget-wrapper ref="wrapper" data-testid="work-item-tree">
    <template #header>
      {{ $options.WORK_ITEMS_TREE_TEXT_MAP[workItemType].title }}
    </template>
    <template #header-right>
      <okr-actions-split-button
        @showCreateObjectiveForm="
          showAddForm($options.FORM_TYPES.create, $options.WORK_ITEM_TYPE_ENUM_OBJECTIVE)
        "
        @showAddObjectiveForm="
          showAddForm($options.FORM_TYPES.add, $options.WORK_ITEM_TYPE_ENUM_OBJECTIVE)
        "
        @showCreateKeyResultForm="
          showAddForm($options.FORM_TYPES.create, $options.WORK_ITEM_TYPE_ENUM_KEY_RESULT)
        "
        @showAddKeyResultForm="
          showAddForm($options.FORM_TYPES.add, $options.WORK_ITEM_TYPE_ENUM_KEY_RESULT)
        "
      />
    </template>
    <template #body>
      <div v-if="!isShownAddForm && children.length === 0" data-testid="tree-empty">
        <p class="gl-mb-3">
          {{ $options.WORK_ITEMS_TREE_TEXT_MAP[workItemType].empty }}
        </p>
      </div>
      <work-item-links-form
        v-if="isShownAddForm"
        ref="wiLinksForm"
        data-testid="add-tree-form"
        :issuable-gid="workItemId"
        :form-type="formType"
        :parent-work-item-type="parentWorkItemType"
        :children-type="childType"
        :children-ids="childrenIds"
        :parent-confidential="confidential"
        @addWorkItemChild="$emit('addWorkItemChild', $event)"
        @cancel="hideAddForm"
      />
      <work-item-link-child
        v-for="child in children"
        :key="child.id"
        :project-path="projectPath"
        :can-update="canUpdate"
        :issuable-gid="workItemId"
        :child-item="child"
        :confidential="child.confidential"
        :work-item-type="workItemType"
        :has-indirect-children="hasIndirectChildren"
        @mouseover="prefetchWorkItem(child)"
        @mouseout="clearPrefetching"
        @removeChild="$emit('removeChild', $event)"
        @click="$emit('show-modal', $event, $event.childItem || child)"
      />
    </template>
  </widget-wrapper>
</template>
