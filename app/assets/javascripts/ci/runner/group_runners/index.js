import { GlToast } from '@gitlab/ui';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import { createLocalState } from '../graphql/list/local_state';
import GroupRunnersApp from './group_runners_app.vue';

Vue.use(GlToast);
Vue.use(VueApollo);

export const initGroupRunners = (selector = '#js-group-runners') => {
  const el = document.querySelector(selector);

  if (!el) {
    return null;
  }

  const {
    registrationToken,
    runnerInstallHelpPage,
    groupId,
    groupFullPath,
    onlineContactTimeoutSecs,
    staleTimeoutSecs,
    emptyStateSvgPath,
    emptyStateFilteredSvgPath,
  } = el.dataset;

  const { cacheConfig, typeDefs, localMutations } = createLocalState();

  const apolloProvider = new VueApollo({
    defaultClient: createDefaultClient({}, { cacheConfig, typeDefs }),
  });

  return new Vue({
    el,
    apolloProvider,
    provide: {
      runnerInstallHelpPage,
      localMutations,
      groupId,
      onlineContactTimeoutSecs: parseInt(onlineContactTimeoutSecs, 10),
      staleTimeoutSecs: parseInt(staleTimeoutSecs, 10),
      emptyStateSvgPath,
      emptyStateFilteredSvgPath,
    },
    render(h) {
      return h(GroupRunnersApp, {
        props: {
          registrationToken,
          groupFullPath,
        },
      });
    },
  });
};
