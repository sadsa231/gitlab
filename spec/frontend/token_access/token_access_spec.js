import { GlToggle, GlLoadingIcon } from '@gitlab/ui';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import { mountExtended, shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/flash';
import OptInJwt from '~/token_access/components/opt_in_jwt.vue';
import TokenAccess from '~/token_access/components/token_access.vue';
import addProjectCIJobTokenScopeMutation from '~/token_access/graphql/mutations/add_project_ci_job_token_scope.mutation.graphql';
import removeProjectCIJobTokenScopeMutation from '~/token_access/graphql/mutations/remove_project_ci_job_token_scope.mutation.graphql';
import updateCIJobTokenScopeMutation from '~/token_access/graphql/mutations/update_ci_job_token_scope.mutation.graphql';
import getCIJobTokenScopeQuery from '~/token_access/graphql/queries/get_ci_job_token_scope.query.graphql';
import getProjectsWithCIJobTokenScopeQuery from '~/token_access/graphql/queries/get_projects_with_ci_job_token_scope.query.graphql';
import {
  enabledJobTokenScope,
  disabledJobTokenScope,
  projectsWithScope,
  addProjectSuccess,
  removeProjectSuccess,
  updateScopeSuccess,
} from './mock_data';

const projectPath = 'root/my-repo';
const message = 'An error occurred';
const error = new Error(message);

Vue.use(VueApollo);

jest.mock('~/flash');

describe('TokenAccess component', () => {
  let wrapper;

  const enabledJobTokenScopeHandler = jest.fn().mockResolvedValue(enabledJobTokenScope);
  const disabledJobTokenScopeHandler = jest.fn().mockResolvedValue(disabledJobTokenScope);
  const getProjectsWithScopeHandler = jest.fn().mockResolvedValue(projectsWithScope);
  const addProjectSuccessHandler = jest.fn().mockResolvedValue(addProjectSuccess);
  const removeProjectSuccessHandler = jest.fn().mockResolvedValue(removeProjectSuccess);
  const updateScopeSuccessHandler = jest.fn().mockResolvedValue(updateScopeSuccess);
  const failureHandler = jest.fn().mockRejectedValue(error);

  const findToggle = () => wrapper.findComponent(GlToggle);
  const findOptInJwt = () => wrapper.findComponent(OptInJwt);
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findAddProjectBtn = () => wrapper.findByRole('button', { name: 'Add project' });
  const findRemoveProjectBtn = () => wrapper.findByRole('button', { name: 'Remove access' });
  const findTokenDisabledAlert = () => wrapper.findByTestId('token-disabled-alert');

  const createMockApolloProvider = (requestHandlers) => {
    return createMockApollo(requestHandlers);
  };

  const createComponent = (requestHandlers, mountFn = shallowMountExtended) => {
    wrapper = mountFn(TokenAccess, {
      provide: {
        fullPath: projectPath,
      },
      apolloProvider: createMockApolloProvider(requestHandlers),
      data() {
        return {
          targetProjectPath: 'root/test',
        };
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('loading state', () => {
    it('shows loading state while waiting on query to resolve', async () => {
      createComponent([
        [getCIJobTokenScopeQuery, enabledJobTokenScopeHandler],
        [getProjectsWithCIJobTokenScopeQuery, getProjectsWithScopeHandler],
      ]);

      expect(findLoadingIcon().exists()).toBe(true);

      await waitForPromises();

      expect(findLoadingIcon().exists()).toBe(false);
    });
  });

  describe('template', () => {
    beforeEach(async () => {
      createComponent([
        [getCIJobTokenScopeQuery, enabledJobTokenScopeHandler],
        [getProjectsWithCIJobTokenScopeQuery, getProjectsWithScopeHandler],
      ]);

      await waitForPromises();
    });

    it('renders the opt in jwt component', () => {
      expect(findOptInJwt().exists()).toBe(true);
    });
  });

  describe('fetching projects and scope', () => {
    it('fetches projects and scope correctly', () => {
      const expectedVariables = {
        fullPath: 'root/my-repo',
      };

      createComponent([
        [getCIJobTokenScopeQuery, enabledJobTokenScopeHandler],
        [getProjectsWithCIJobTokenScopeQuery, getProjectsWithScopeHandler],
      ]);

      expect(enabledJobTokenScopeHandler).toHaveBeenCalledWith(expectedVariables);
      expect(getProjectsWithScopeHandler).toHaveBeenCalledWith(expectedVariables);
    });

    it('handles fetch projects error correctly', async () => {
      createComponent([
        [getCIJobTokenScopeQuery, enabledJobTokenScopeHandler],
        [getProjectsWithCIJobTokenScopeQuery, failureHandler],
      ]);

      await waitForPromises();

      expect(createAlert).toHaveBeenCalledWith({
        message: 'There was a problem fetching the projects',
      });
    });

    it('handles fetch scope error correctly', async () => {
      createComponent([
        [getCIJobTokenScopeQuery, failureHandler],
        [getProjectsWithCIJobTokenScopeQuery, getProjectsWithScopeHandler],
      ]);

      await waitForPromises();

      expect(createAlert).toHaveBeenCalledWith({
        message: 'There was a problem fetching the job token scope value',
      });
    });
  });

  describe('toggle', () => {
    it('the toggle is on and the alert is hidden', async () => {
      createComponent([
        [getCIJobTokenScopeQuery, enabledJobTokenScopeHandler],
        [getProjectsWithCIJobTokenScopeQuery, getProjectsWithScopeHandler],
      ]);

      await waitForPromises();

      expect(findToggle().props('value')).toBe(true);
      expect(findTokenDisabledAlert().exists()).toBe(false);
    });

    it('the toggle is off and the alert is visible', async () => {
      createComponent([
        [getCIJobTokenScopeQuery, disabledJobTokenScopeHandler],
        [getProjectsWithCIJobTokenScopeQuery, getProjectsWithScopeHandler],
      ]);

      await waitForPromises();

      expect(findToggle().props('value')).toBe(false);
      expect(findTokenDisabledAlert().exists()).toBe(true);
    });

    describe('update ci job token scope', () => {
      it('calls updateCIJobTokenScopeMutation mutation', async () => {
        createComponent(
          [
            [getCIJobTokenScopeQuery, enabledJobTokenScopeHandler],
            [updateCIJobTokenScopeMutation, updateScopeSuccessHandler],
          ],
          mountExtended,
        );

        await waitForPromises();

        findToggle().vm.$emit('change', false);

        expect(updateScopeSuccessHandler).toHaveBeenCalledWith({
          input: {
            fullPath: 'root/my-repo',
            jobTokenScopeEnabled: false,
          },
        });
      });

      it('handles update scope error correctly', async () => {
        createComponent(
          [
            [getCIJobTokenScopeQuery, disabledJobTokenScopeHandler],
            [updateCIJobTokenScopeMutation, failureHandler],
          ],
          mountExtended,
        );

        await waitForPromises();

        findToggle().vm.$emit('change', true);

        await waitForPromises();

        expect(createAlert).toHaveBeenCalledWith({ message });
      });
    });
  });

  describe('add project', () => {
    it('calls add project mutation', async () => {
      createComponent(
        [
          [getCIJobTokenScopeQuery, enabledJobTokenScopeHandler],
          [getProjectsWithCIJobTokenScopeQuery, getProjectsWithScopeHandler],
          [addProjectCIJobTokenScopeMutation, addProjectSuccessHandler],
        ],
        mountExtended,
      );

      await waitForPromises();

      findAddProjectBtn().trigger('click');

      expect(addProjectSuccessHandler).toHaveBeenCalledWith({
        input: {
          projectPath,
          targetProjectPath: 'root/test',
        },
      });
    });

    it('add project handles error correctly', async () => {
      createComponent(
        [
          [getCIJobTokenScopeQuery, enabledJobTokenScopeHandler],
          [getProjectsWithCIJobTokenScopeQuery, getProjectsWithScopeHandler],
          [addProjectCIJobTokenScopeMutation, failureHandler],
        ],
        mountExtended,
      );

      await waitForPromises();

      findAddProjectBtn().trigger('click');

      await waitForPromises();

      expect(createAlert).toHaveBeenCalledWith({ message });
    });
  });

  describe('remove project', () => {
    it('calls remove project mutation', async () => {
      createComponent(
        [
          [getCIJobTokenScopeQuery, enabledJobTokenScopeHandler],
          [getProjectsWithCIJobTokenScopeQuery, getProjectsWithScopeHandler],
          [removeProjectCIJobTokenScopeMutation, removeProjectSuccessHandler],
        ],
        mountExtended,
      );

      await waitForPromises();

      findRemoveProjectBtn().trigger('click');

      expect(removeProjectSuccessHandler).toHaveBeenCalledWith({
        input: {
          projectPath,
          targetProjectPath: 'root/332268-test',
        },
      });
    });

    it('remove project handles error correctly', async () => {
      createComponent(
        [
          [getCIJobTokenScopeQuery, enabledJobTokenScopeHandler],
          [getProjectsWithCIJobTokenScopeQuery, getProjectsWithScopeHandler],
          [removeProjectCIJobTokenScopeMutation, failureHandler],
        ],
        mountExtended,
      );

      await waitForPromises();

      findRemoveProjectBtn().trigger('click');

      await waitForPromises();

      expect(createAlert).toHaveBeenCalledWith({ message });
    });
  });
});
