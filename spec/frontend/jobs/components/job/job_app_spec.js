import Vue, { nextTick } from 'vue';
import Vuex from 'vuex';
import { GlLoadingIcon } from '@gitlab/ui';
import MockAdapter from 'axios-mock-adapter';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { TEST_HOST } from 'helpers/test_constants';
import EmptyState from '~/jobs/components/job/empty_state.vue';
import EnvironmentsBlock from '~/jobs/components/job/environments_block.vue';
import ErasedBlock from '~/jobs/components/job/erased_block.vue';
import JobApp from '~/jobs/components/job/job_app.vue';
import JobLog from '~/jobs/components/log/log.vue';
import JobLogTopBar from '~/jobs/components/job/job_log_controllers.vue';
import Sidebar from '~/jobs/components/job/sidebar/sidebar.vue';
import StuckBlock from '~/jobs/components/job/stuck_block.vue';
import UnmetPrerequisitesBlock from '~/jobs/components/job/unmet_prerequisites_block.vue';
import createStore from '~/jobs/store';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';
import job from '../../mock_data';

describe('Job App', () => {
  Vue.use(Vuex);

  let store;
  let wrapper;
  let mock;

  const initSettings = {
    endpoint: `${TEST_HOST}jobs/123.json`,
    pagePath: `${TEST_HOST}jobs/123`,
    logState:
      'eyJvZmZzZXQiOjE3NDUxLCJuX29wZW5fdGFncyI6MCwiZmdfY29sb3IiOm51bGwsImJnX2NvbG9yIjpudWxsLCJzdHlsZV9tYXNrIjowfQ%3D%3D',
  };

  const props = {
    artifactHelpUrl: 'help/artifact',
    deploymentHelpUrl: 'help/deployment',
    runnerSettingsUrl: 'settings/ci-cd/runners',
    terminalPath: 'jobs/123/terminal',
    projectPath: 'user-name/project-name',
    subscriptionsMoreMinutesUrl: 'https://customers.gitlab.com/buy_pipeline_minutes',
  };

  const createComponent = () => {
    wrapper = shallowMountExtended(JobApp, {
      propsData: { ...props },
      store,
    });
  };

  const setupAndMount = async ({ jobData = {}, jobLogData = {} } = {}) => {
    mock.onGet(initSettings.endpoint).replyOnce(HTTP_STATUS_OK, { ...job, ...jobData });
    mock.onGet(`${initSettings.pagePath}/trace.json`).reply(HTTP_STATUS_OK, jobLogData);

    const asyncInit = store.dispatch('init', initSettings);

    createComponent();

    await asyncInit;
    jest.runOnlyPendingTimers();
    await axios.waitForAll();
    await nextTick();
  };

  const findLoadingComponent = () => wrapper.findComponent(GlLoadingIcon);
  const findSidebar = () => wrapper.findComponent(Sidebar);
  const findStuckBlockComponent = () => wrapper.findComponent(StuckBlock);
  const findFailedJobComponent = () => wrapper.findComponent(UnmetPrerequisitesBlock);
  const findEnvironmentsBlockComponent = () => wrapper.findComponent(EnvironmentsBlock);
  const findErasedBlock = () => wrapper.findComponent(ErasedBlock);
  const findEmptyState = () => wrapper.findComponent(EmptyState);
  const findJobLog = () => wrapper.findComponent(JobLog);
  const findJobLogTopBar = () => wrapper.findComponent(JobLogTopBar);

  const findJobContent = () => wrapper.findByTestId('job-content');
  const findArchivedJob = () => wrapper.findByTestId('archived-job');

  beforeEach(() => {
    mock = new MockAdapter(axios);
    store = createStore();
  });

  afterEach(() => {
    wrapper.destroy();
    mock.restore();
  });

  describe('while loading', () => {
    beforeEach(() => {
      store.state.isLoading = true;
      createComponent();
    });

    it('renders loading icon', () => {
      expect(findLoadingComponent().exists()).toBe(true);
      expect(findSidebar().exists()).toBe(false);
      expect(findJobContent().exists()).toBe(false);
    });
  });

  describe('with successful request', () => {
    describe('Header section', () => {
      describe('job callout message', () => {
        it('should not render the reason when reason is absent', () =>
          setupAndMount().then(() => {
            expect(wrapper.vm.shouldRenderCalloutMessage).toBe(false);
          }));

        it('should render the reason when reason is present', () =>
          setupAndMount({
            jobData: {
              callout_message: 'There is an unkown failure, please try again',
            },
          }).then(() => {
            expect(wrapper.vm.shouldRenderCalloutMessage).toBe(true);
          }));
      });
    });

    describe('stuck block', () => {
      describe('without active runners available', () => {
        it('renders stuck block when there are no runners', () =>
          setupAndMount({
            jobData: {
              status: {
                group: 'pending',
                icon: 'status_pending',
                label: 'pending',
                text: 'pending',
                details_path: 'path',
              },
              stuck: true,
              runners: {
                available: false,
                online: false,
              },
              tags: [],
            },
          }).then(() => {
            expect(findStuckBlockComponent().exists()).toBe(true);
          }));
      });

      it('does not render stuck block when there are runners', () =>
        setupAndMount({
          jobData: {
            runners: { available: true },
          },
        }).then(() => {
          expect(findStuckBlockComponent().exists()).toBe(false);
        }));
    });

    describe('unmet prerequisites block', () => {
      it('renders unmet prerequisites block when there is an unmet prerequisites failure', () =>
        setupAndMount({
          jobData: {
            status: {
              group: 'failed',
              icon: 'status_failed',
              label: 'failed',
              text: 'failed',
              details_path: 'path',
              illustration: {
                content: 'Retry this job in order to create the necessary resources.',
                image: 'path',
                size: 'svg-430',
                title: 'Failed to create resources',
              },
            },
            failure_reason: 'unmet_prerequisites',
            has_trace: false,
            runners: {
              available: true,
            },
            tags: [],
          },
        }).then(() => {
          expect(findFailedJobComponent().exists()).toBe(true);
        }));
    });

    describe('environments block', () => {
      it('renders environment block when job has environment', () =>
        setupAndMount({
          jobData: {
            deployment_status: {
              environment: {
                environment_path: '/path',
                name: 'foo',
              },
            },
          },
        }).then(() => {
          expect(findEnvironmentsBlockComponent().exists()).toBe(true);
        }));

      it('does not render environment block when job has environment', () =>
        setupAndMount().then(() => {
          expect(findEnvironmentsBlockComponent().exists()).toBe(false);
        }));
    });

    describe('erased block', () => {
      it('renders erased block when `erased` is true', () =>
        setupAndMount({
          jobData: {
            erased_by: {
              username: 'root',
              web_url: 'gitlab.com/root',
            },
            erased_at: '2016-11-07T11:11:16.525Z',
          },
        }).then(() => {
          expect(findErasedBlock().exists()).toBe(true);
        }));

      it('does not render erased block when `erased` is false', () =>
        setupAndMount({
          jobData: {
            erased_at: null,
          },
        }).then(() => {
          expect(findErasedBlock().exists()).toBe(false);
        }));
    });

    describe('empty states block', () => {
      it('renders empty state when job does not have log and is not running', () =>
        setupAndMount({
          jobData: {
            has_trace: false,
            status: {
              group: 'pending',
              icon: 'status_pending',
              label: 'pending',
              text: 'pending',
              details_path: 'path',
              illustration: {
                image: 'path',
                size: '340',
                title: 'Empty State',
                content: 'This is an empty state',
              },
              action: {
                button_title: 'Retry job',
                method: 'post',
                path: '/path',
              },
            },
          },
        }).then(() => {
          expect(findEmptyState().exists()).toBe(true);
        }));

      it('does not render empty state when job does not have log but it is running', () =>
        setupAndMount({
          jobData: {
            has_trace: false,
            status: {
              group: 'running',
              icon: 'status_running',
              label: 'running',
              text: 'running',
              details_path: 'path',
            },
          },
        }).then(() => {
          expect(findEmptyState().exists()).toBe(false);
        }));

      it('does not render empty state when job has log but it is not running', () =>
        setupAndMount({ jobData: { has_trace: true } }).then(() => {
          expect(findEmptyState().exists()).toBe(false);
        }));
    });

    describe('sidebar', () => {
      it('renders sidebar', async () => {
        await setupAndMount();

        expect(findSidebar().exists()).toBe(true);
      });
    });
  });

  describe('archived job', () => {
    beforeEach(() => setupAndMount({ jobData: { archived: true } }));

    it('renders warning about job being archived', () => {
      expect(findArchivedJob().exists()).toBe(true);
    });
  });

  describe('non-archived job', () => {
    beforeEach(() => setupAndMount());

    it('does not warning about job being archived', () => {
      expect(findArchivedJob().exists()).toBe(false);
    });
  });

  describe('job log', () => {
    beforeEach(() => setupAndMount());

    it('should render job log header', () => {
      expect(findJobLogTopBar().exists()).toBe(true);
    });

    it('should render job log', () => {
      expect(findJobLog().exists()).toBe(true);
    });
  });
});
