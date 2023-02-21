import Vue from 'vue';
import { parseBoolean } from '~/lib/utils/common_utils';
import { apolloProvider } from '~/graphql_shared/issuable_client';
import App from './components/app.vue';
import { createRouter } from './router';

export const initWorkItemsRoot = () => {
  const el = document.querySelector('#js-work-items');
  const {
    fullPath,
    hasIssueWeightsFeature,
    issuesListPath,
    registerPath,
    signInPath,
    hasIterationsFeature,
    hasOkrsFeature,
    hasIssuableHealthStatusFeature,
  } = el.dataset;

  return new Vue({
    el,
    name: 'WorkItemsRoot',
    router: createRouter(el.dataset.fullPath),
    apolloProvider,
    provide: {
      fullPath,
      projectPath: fullPath,
      hasIssueWeightsFeature: parseBoolean(hasIssueWeightsFeature),
      hasOkrsFeature: parseBoolean(hasOkrsFeature),
      issuesListPath,
      registerPath,
      signInPath,
      hasIterationsFeature: parseBoolean(hasIterationsFeature),
      hasIssuableHealthStatusFeature: parseBoolean(hasIssuableHealthStatusFeature),
    },
    render(createElement) {
      return createElement(App);
    },
  });
};
