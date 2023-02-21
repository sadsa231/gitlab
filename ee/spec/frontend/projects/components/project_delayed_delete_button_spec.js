import { shallowMount } from '@vue/test-utils';
import { GlSprintf } from '@gitlab/ui';
import ProjectDelayedDeleteButton from 'ee/projects/components/project_delayed_delete_button.vue';
import SharedDeleteButton from '~/projects/components/shared/delete_button.vue';

jest.mock('lodash/uniqueId', () => () => 'fakeUniqueId');

describe('Project delayed delete modal', () => {
  let wrapper;

  const findSharedDeleteButton = () => wrapper.findComponent(SharedDeleteButton);

  const defaultProps = {
    delayedDeletionDate: '2020-12-12',
    confirmPhrase: 'foo',
    formPath: 'some/path',
    restoreHelpPath: 'recovery/help/path',
    isFork: false,
    issuesCount: 1,
    mergeRequestsCount: 2,
    forksCount: 3,
    starsCount: 4,
  };

  const createComponent = (props = {}) => {
    wrapper = shallowMount(ProjectDelayedDeleteButton, {
      propsData: {
        ...defaultProps,
        ...props,
      },
      stubs: {
        GlSprintf,
        SharedDeleteButton,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('initialized', () => {
    beforeEach(() => {
      createComponent();
    });

    it('matches the snapshot', () => {
      expect(wrapper.element).toMatchSnapshot();
    });

    it('passes confirmPhrase and formPath props to the shared delete button', () => {
      expect(findSharedDeleteButton().props()).toEqual({
        confirmPhrase: defaultProps.confirmPhrase,
        forksCount: defaultProps.forksCount,
        formPath: defaultProps.formPath,
        isFork: defaultProps.isFork,
        issuesCount: defaultProps.issuesCount,
        mergeRequestsCount: defaultProps.mergeRequestsCount,
        starsCount: defaultProps.starsCount,
      });
    });
  });
});
