<script>
import { GlCollapse } from '@gitlab/ui';
import { context } from '../mock_data';
import UserBar from './user_bar.vue';
import ContextSwitcherToggle from './context_switcher_toggle.vue';
import ContextSwitcher from './context_switcher.vue';
import HelpCenter from './help_center.vue';

export default {
  context,
  components: {
    GlCollapse,
    UserBar,
    ContextSwitcherToggle,
    ContextSwitcher,
    HelpCenter,
  },
  props: {
    sidebarData: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      contextSwitcherOpened: false,
    };
  },
};
</script>

<template>
  <aside
    id="super-sidebar"
    class="super-sidebar gl-fixed gl-bottom-0 gl-left-0 gl-display-flex gl-flex-direction-column gl-bg-gray-10 gl-border-r gl-border-gray-a-08"
    data-testid="super-sidebar"
  >
    <user-bar :sidebar-data="sidebarData" />
    <div class="gl-display-flex gl-flex-direction-column gl-flex-grow-1 gl-overflow-hidden">
      <div class="gl-flex-grow-1 gl-overflow-auto">
        <context-switcher-toggle :context="$options.context" :expanded="contextSwitcherOpened" />
        <gl-collapse id="context-switcher" v-model="contextSwitcherOpened">
          <context-switcher />
        </gl-collapse>
      </div>
      <div class="gl-p-3">
        <help-center :sidebar-data="sidebarData" />
      </div>
    </div>
  </aside>
</template>
