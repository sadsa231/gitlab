import { GlLoadingIcon, GlToggle } from '@gitlab/ui';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import { mountExtended, shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/flash';
import OptInJwt from '~/token_access/components/opt_in_jwt.vue';
import getOptInJwtSettingQuery from '~/token_access/graphql/queries/get_opt_in_jwt_setting.query.graphql';
import updateOptInJwtMutation from '~/token_access/graphql/mutations/update_opt_in_jwt.mutation.graphql';
import { optInJwtMutationResponse, optInJwtQueryResponse } from './mock_data';

const errorMessage = 'An error occurred';
const error = new Error(errorMessage);

Vue.use(VueApollo);

jest.mock('~/flash');

describe('OptInJwt component', () => {
  let wrapper;

  const failureHandler = jest.fn().mockRejectedValue(error);
  const enabledOptInJwtHandler = jest.fn().mockResolvedValue(optInJwtQueryResponse(true));
  const disabledOptInJwtHandler = jest.fn().mockResolvedValue(optInJwtQueryResponse(false));
  const updateOptInJwtHandler = jest.fn().mockResolvedValue(optInJwtMutationResponse(true));

  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findToggle = () => wrapper.findComponent(GlToggle);
  const findOptInJwtExpandedSection = () => wrapper.findByTestId('opt-in-jwt-expanded-section');

  const createMockApolloProvider = (requestHandlers) => {
    return createMockApollo(requestHandlers);
  };

  const createComponent = (requestHandlers, mountFn = shallowMountExtended) => {
    wrapper = mountFn(OptInJwt, {
      provide: {
        fullPath: 'root/my-repo',
      },
      apolloProvider: createMockApolloProvider(requestHandlers),
      data() {
        return {
          targetProjectPath: 'root/test',
        };
      },
    });
  };

  describe('loading state', () => {
    it('shows loading state and hides toggle while waiting on query to resolve', async () => {
      createComponent([[getOptInJwtSettingQuery, enabledOptInJwtHandler]]);

      expect(findLoadingIcon().exists()).toBe(true);
      expect(findToggle().exists()).toBe(false);

      await waitForPromises();

      expect(findLoadingIcon().exists()).toBe(false);
      expect(findToggle().exists()).toBe(true);
    });
  });

  describe('toggle JWT token access', () => {
    it('code instruction is visible when toggle is enabled', async () => {
      createComponent([[getOptInJwtSettingQuery, enabledOptInJwtHandler]]);

      await waitForPromises();

      expect(findToggle().props('value')).toBe(true);
      expect(findOptInJwtExpandedSection().exists()).toBe(true);
    });

    it('code instruction is hidden when toggle is disabled', async () => {
      createComponent([[getOptInJwtSettingQuery, disabledOptInJwtHandler]]);

      await waitForPromises();

      expect(findToggle().props('value')).toBe(false);
      expect(findOptInJwtExpandedSection().exists()).toBe(false);
    });

    describe('update JWT token access', () => {
      it('calls updateOptInJwtMutation with correct arguments', async () => {
        createComponent(
          [
            [getOptInJwtSettingQuery, disabledOptInJwtHandler],
            [updateOptInJwtMutation, updateOptInJwtHandler],
          ],
          mountExtended,
        );

        await waitForPromises();

        findToggle().vm.$emit('change', true);

        expect(updateOptInJwtHandler).toHaveBeenCalledWith({
          input: {
            fullPath: 'root/my-repo',
            optInJwt: true,
          },
        });
      });

      it('handles update error', async () => {
        createComponent(
          [
            [getOptInJwtSettingQuery, enabledOptInJwtHandler],
            [updateOptInJwtMutation, failureHandler],
          ],
          mountExtended,
        );

        await waitForPromises();

        findToggle().vm.$emit('change', false);

        await waitForPromises();

        expect(createAlert).toHaveBeenCalledWith({
          message: 'An error occurred while update the setting. Please try again.',
        });
      });
    });
  });
});
