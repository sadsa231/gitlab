import VueRouter from 'vue-router';
import { createAlert } from '~/flash';
import { __ } from '~/locale';
import { createPipelineHeaderApp } from './pipeline_details_header';
import { apolloProvider } from './pipeline_shared_client';

const SELECTORS = {
  PIPELINE_HEADER: '#js-pipeline-header-vue',
  PIPELINE_TABS: '#js-pipeline-tabs',
};

export default async function initPipelineDetailsBundle() {
  const { dataset: headerDataset } = document.querySelector(SELECTORS.PIPELINE_HEADER);

  try {
    createPipelineHeaderApp(
      SELECTORS.PIPELINE_HEADER,
      apolloProvider,
      headerDataset.graphqlResourceEtag,
    );
  } catch {
    createAlert({
      message: __('An error occurred while loading a section of this page.'),
    });
  }

  const tabsEl = document.querySelector(SELECTORS.PIPELINE_TABS);

  if (tabsEl) {
    const { dataset } = tabsEl;
    const { createAppOptions } = await import('ee_else_ce/pipelines/pipeline_tabs');
    const { createPipelineTabs } = await import('./pipeline_tabs');
    const { routes } = await import('ee_else_ce/pipelines/routes');

    const router = new VueRouter({
      mode: 'history',
      base: dataset.pipelinePath,
      routes,
    });

    try {
      const appOptions = createAppOptions(SELECTORS.PIPELINE_TABS, apolloProvider, router);
      createPipelineTabs(appOptions);
    } catch {
      createAlert({
        message: __('An error occurred while loading a section of this page.'),
      });
    }
  }
}
