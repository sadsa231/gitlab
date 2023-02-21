import { GlEmptyState } from '@gitlab/ui';

import { mountExtended } from 'helpers/vue_test_utils_helper';
import SharedProjectsEmptyState from '~/groups/components/empty_states/shared_projects_empty_state.vue';

let wrapper;

const defaultProvide = {
  newProjectIllustration: '/assets/illustrations/project-create-new-sm.svg',
};

const createComponent = () => {
  wrapper = mountExtended(SharedProjectsEmptyState, {
    provide: defaultProvide,
  });
};

describe('SharedProjectsEmptyState', () => {
  it('renders empty state', () => {
    createComponent();

    expect(wrapper.findComponent(GlEmptyState).props()).toMatchObject({
      title: SharedProjectsEmptyState.i18n.title,
      svgPath: defaultProvide.newProjectIllustration,
    });
  });
});
