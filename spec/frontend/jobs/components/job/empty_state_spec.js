import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import EmptyState from '~/jobs/components/job/empty_state.vue';
import ManualVariablesForm from '~/jobs/components/job/manual_variables_form.vue';
import { mockFullPath, mockId } from './mock_data';

describe('Empty State', () => {
  let wrapper;

  const defaultProps = {
    illustrationPath: 'illustrations/pending_job_empty.svg',
    illustrationSizeClass: 'svg-430',
    jobId: mockId,
    title: 'This job has not started yet',
    playable: false,
    isRetryable: true,
  };

  const createWrapper = (props) => {
    wrapper = shallowMountExtended(EmptyState, {
      propsData: {
        ...defaultProps,
        ...props,
      },
      provide: {
        projectPath: mockFullPath,
      },
    });
  };

  const content = 'This job is in pending state and is waiting to be picked by a runner';

  const findEmptyStateImage = () => wrapper.find('img');
  const findTitle = () => wrapper.findByTestId('job-empty-state-title');
  const findContent = () => wrapper.findByTestId('job-empty-state-content');
  const findAction = () => wrapper.findByTestId('job-empty-state-action');
  const findManualVarsForm = () => wrapper.findComponent(ManualVariablesForm);

  afterEach(() => {
    if (wrapper?.destroy) {
      wrapper.destroy();
      wrapper = null;
    }
  });

  describe('renders image and title', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('renders empty state image', () => {
      expect(findEmptyStateImage().exists()).toBe(true);
    });

    it('renders provided title', () => {
      expect(findTitle().text().trim()).toBe(defaultProps.title);
    });
  });

  describe('with content', () => {
    beforeEach(() => {
      createWrapper({ content });
    });

    it('renders content', () => {
      expect(findContent().text().trim()).toBe(content);
    });
  });

  describe('without content', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('does not render content', () => {
      expect(findContent().exists()).toBe(false);
    });
  });

  describe('with action', () => {
    beforeEach(() => {
      createWrapper({
        action: {
          path: 'runner',
          button_title: 'Check runner',
          method: 'post',
        },
      });
    });

    it('renders action', () => {
      expect(findAction().attributes('href')).toBe('runner');
    });
  });

  describe('without action', () => {
    beforeEach(() => {
      createWrapper({
        action: null,
      });
    });

    it('does not render action', () => {
      expect(findAction().exists()).toBe(false);
    });

    it('does not render manual variables form', () => {
      expect(findManualVarsForm().exists()).toBe(false);
    });
  });

  describe('with playable action and not scheduled job', () => {
    beforeEach(() => {
      createWrapper({
        content,
        playable: true,
        scheduled: false,
        action: {
          path: 'runner',
          button_title: 'Check runner',
          method: 'post',
        },
      });
    });

    it('renders manual variables form', () => {
      expect(findManualVarsForm().exists()).toBe(true);
    });

    it('does not render the empty state action', () => {
      expect(findAction().exists()).toBe(false);
    });
  });

  describe('with playable action and scheduled job', () => {
    beforeEach(() => {
      createWrapper({
        playable: true,
        scheduled: true,
        content,
      });
    });

    it('does not render manual variables form', () => {
      expect(findManualVarsForm().exists()).toBe(false);
    });
  });
});
