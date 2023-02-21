import { start } from '@gitlab/web-ide';
import { GITLAB_WEB_IDE_FEEDBACK_ISSUE } from '~/ide/constants';
import { initGitlabWebIDE } from '~/ide/init_gitlab_web_ide';
import { confirmAction } from '~/lib/utils/confirm_via_gl_modal/confirm_action';
import { createAndSubmitForm } from '~/lib/utils/create_and_submit_form';
import { TEST_HOST } from 'helpers/test_constants';
import setWindowLocation from 'helpers/set_window_location_helper';
import waitForPromises from 'helpers/wait_for_promises';

jest.mock('@gitlab/web-ide');
jest.mock('~/lib/utils/confirm_via_gl_modal/confirm_action');
jest.mock('~/lib/utils/create_and_submit_form');
jest.mock('~/lib/utils/csrf', () => ({
  token: 'mock-csrf-token',
  headerKey: 'mock-csrf-header',
}));

const ROOT_ELEMENT_ID = 'ide';
const TEST_NONCE = 'test123nonce';
const TEST_PROJECT_PATH = 'group1/project1';
const TEST_BRANCH_NAME = '12345-foo-patch';
const TEST_GITLAB_URL = 'https://test-gitlab/';
const TEST_USER_PREFERENCES_PATH = '/user/preferences';
const TEST_GITLAB_WEB_IDE_PUBLIC_PATH = 'test/webpack/assets/gitlab-web-ide/public/path';
const TEST_FILE_PATH = 'foo/README.md';
const TEST_MR_ID = '7';
const TEST_MR_TARGET_PROJECT = 'gitlab-org/the-real-gitlab';
const TEST_FORK_INFO = { fork_path: '/forky' };
const TEST_IDE_REMOTE_PATH = '/-/ide/remote/:remote_host/:remote_path';
const TEST_START_REMOTE_PARAMS = {
  remoteHost: 'dev.example.gitlab.com/test',
  remotePath: '/test/projects/f oo',
  connectionToken: '123abc',
};

describe('ide/init_gitlab_web_ide', () => {
  let resolveConfirm;

  const createRootElement = () => {
    const el = document.createElement('div');

    el.id = ROOT_ELEMENT_ID;
    // why: We'll test that this class is removed later
    el.classList.add('test-class');
    el.dataset.projectPath = TEST_PROJECT_PATH;
    el.dataset.cspNonce = TEST_NONCE;
    el.dataset.branchName = TEST_BRANCH_NAME;
    el.dataset.ideRemotePath = TEST_IDE_REMOTE_PATH;
    el.dataset.userPreferencesPath = TEST_USER_PREFERENCES_PATH;
    el.dataset.mergeRequest = TEST_MR_ID;
    el.dataset.filePath = TEST_FILE_PATH;

    document.body.append(el);
  };
  const findRootElement = () => document.getElementById(ROOT_ELEMENT_ID);
  const createSubject = () => initGitlabWebIDE(findRootElement());
  const triggerHandleStartRemote = (startRemoteParams) => {
    const [, config] = start.mock.calls[0];

    config.handleStartRemote(startRemoteParams);
  };

  beforeEach(() => {
    process.env.GITLAB_WEB_IDE_PUBLIC_PATH = TEST_GITLAB_WEB_IDE_PUBLIC_PATH;
    window.gon.gitlab_url = TEST_GITLAB_URL;

    confirmAction.mockImplementation(
      () =>
        new Promise((resolve) => {
          resolveConfirm = resolve;
        }),
    );

    createRootElement();
  });

  afterEach(() => {
    document.body.innerHTML = '';
  });

  describe('default', () => {
    beforeEach(() => {
      createSubject();
    });

    it('calls start with element', () => {
      expect(start).toHaveBeenCalledTimes(1);
      expect(start).toHaveBeenCalledWith(findRootElement(), {
        baseUrl: `${TEST_HOST}/${TEST_GITLAB_WEB_IDE_PUBLIC_PATH}`,
        projectPath: TEST_PROJECT_PATH,
        ref: TEST_BRANCH_NAME,
        filePath: TEST_FILE_PATH,
        mrId: TEST_MR_ID,
        mrTargetProject: '',
        forkInfo: null,
        gitlabUrl: TEST_GITLAB_URL,
        nonce: TEST_NONCE,
        httpHeaders: {
          'mock-csrf-header': 'mock-csrf-token',
          'X-Requested-With': 'XMLHttpRequest',
        },
        links: {
          userPreferences: TEST_USER_PREFERENCES_PATH,
          feedbackIssue: GITLAB_WEB_IDE_FEEDBACK_ISSUE,
        },
        handleStartRemote: expect.any(Function),
      });
    });

    it('clears classes and data from root element', () => {
      const rootEl = findRootElement();

      // why: Snapshot to test that the element was cleaned including `test-class`
      expect(rootEl.outerHTML).toBe(
        '<div id="ide" class="gl--flex-center gl-relative gl-h-full"></div>',
      );
    });

    describe('when handleStartRemote is triggered', () => {
      beforeEach(() => {
        triggerHandleStartRemote(TEST_START_REMOTE_PARAMS);
      });

      it('promts for confirm', () => {
        expect(confirmAction).toHaveBeenCalledWith(expect.any(String), {
          primaryBtnText: expect.any(String),
          cancelBtnText: expect.any(String),
        });
      });

      it('does not submit, when not confirmed', async () => {
        resolveConfirm(false);

        await waitForPromises();

        expect(createAndSubmitForm).not.toHaveBeenCalled();
      });

      it('submits, when confirmed', async () => {
        resolveConfirm(true);

        await waitForPromises();

        expect(createAndSubmitForm).toHaveBeenCalledWith({
          url: '/-/ide/remote/dev.example.gitlab.com%2Ftest/test/projects/f%20oo',
          data: {
            connection_token: TEST_START_REMOTE_PARAMS.connectionToken,
            return_url: window.location.href,
          },
        });
      });
    });
  });

  describe('when URL has target_project in query params', () => {
    beforeEach(() => {
      setWindowLocation(
        `https://example.com/-/ide?target_project=${encodeURIComponent(TEST_MR_TARGET_PROJECT)}`,
      );

      createSubject();
    });

    it('includes mrTargetProject', () => {
      expect(start).toHaveBeenCalledWith(
        findRootElement(),
        expect.objectContaining({
          mrTargetProject: TEST_MR_TARGET_PROJECT,
        }),
      );
    });
  });

  describe('when forkInfo is in dataset', () => {
    beforeEach(() => {
      findRootElement().dataset.forkInfo = JSON.stringify(TEST_FORK_INFO);

      createSubject();
    });

    it('includes forkInfo', () => {
      expect(start).toHaveBeenCalledWith(
        findRootElement(),
        expect.objectContaining({
          forkInfo: TEST_FORK_INFO,
        }),
      );
    });
  });
});
