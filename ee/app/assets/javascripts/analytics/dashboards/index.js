import Vue from 'vue';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import DashboardsApp from './components/app.vue';

const buildNamespaces = ({ groupFullPath, groupName, jsonString = '' }) => {
  const namespaces = jsonString ? JSON.parse(jsonString).map(convertObjectPropsToCamelCase) : [];
  return [
    {
      name: groupName,
      fullPath: groupFullPath,
      isProject: false,
    },
  ].concat(namespaces);
};

export default () => {
  const el = document.querySelector('#js-analytics-dashboards-app');
  const { groupFullPath, groupName, namespaces } = el.dataset;
  const chartConfigs = buildNamespaces({ groupFullPath, groupName, jsonString: namespaces });

  return new Vue({
    el,
    name: 'DashboardsApp',
    render: (createElement) =>
      createElement(DashboardsApp, {
        props: { chartConfigs },
      }),
  });
};
