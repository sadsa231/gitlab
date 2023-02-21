import { GlSprintf, GlLink } from '@gitlab/ui';
import { createLocalVue } from '@vue/test-utils';
import VueApollo from 'vue-apollo';
import { nextTick } from 'vue';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { GRAPHQL_ID_TYPES } from '~/jobs/constants';
import waitForPromises from 'helpers/wait_for_promises';
import ManualVariablesForm from '~/jobs/components/job/manual_variables_form.vue';
import getJobQuery from '~/jobs/components/job/graphql/queries/get_job.query.graphql';
import retryJobMutation from '~/jobs/components/job/graphql/mutations/job_retry_with_variables.mutation.graphql';
import {
  mockFullPath,
  mockId,
  mockJobResponse,
  mockJobWithVariablesResponse,
  mockJobMutationData,
} from './mock_data';

const localVue = createLocalVue();
localVue.use(VueApollo);

const defaultProvide = {
  projectPath: mockFullPath,
};

describe('Manual Variables Form', () => {
  let wrapper;
  let mockApollo;
  let getJobQueryResponse;

  const createComponent = ({ options = {}, props = {} } = {}) => {
    wrapper = mountExtended(ManualVariablesForm, {
      propsData: {
        ...props,
        jobId: mockId,
        isRetryable: true,
      },
      provide: {
        ...defaultProvide,
      },
      ...options,
    });
  };

  const createComponentWithApollo = async ({ props = {} } = {}) => {
    const requestHandlers = [[getJobQuery, getJobQueryResponse]];

    mockApollo = createMockApollo(requestHandlers);

    const options = {
      localVue,
      apolloProvider: mockApollo,
    };

    createComponent({
      props,
      options,
    });

    return waitForPromises();
  };

  const findHelpText = () => wrapper.findComponent(GlSprintf);
  const findHelpLink = () => wrapper.findComponent(GlLink);
  const findCancelBtn = () => wrapper.findByTestId('cancel-btn');
  const findRerunBtn = () => wrapper.findByTestId('run-manual-job-btn');
  const findDeleteVarBtn = () => wrapper.findByTestId('delete-variable-btn');
  const findAllDeleteVarBtns = () => wrapper.findAllByTestId('delete-variable-btn');
  const findDeleteVarBtnPlaceholder = () => wrapper.findByTestId('delete-variable-btn-placeholder');
  const findCiVariableKey = () => wrapper.findByTestId('ci-variable-key');
  const findAllCiVariableKeys = () => wrapper.findAllByTestId('ci-variable-key');
  const findCiVariableValue = () => wrapper.findByTestId('ci-variable-value');
  const findAllVariables = () => wrapper.findAllByTestId('ci-variable-row');

  const setCiVariableKey = () => {
    findCiVariableKey().setValue('new key');
    findCiVariableKey().vm.$emit('change');
    nextTick();
  };

  const setCiVariableKeyByPosition = (position, value) => {
    findAllCiVariableKeys().at(position).setValue(value);
    findAllCiVariableKeys().at(position).vm.$emit('change');
    nextTick();
  };

  beforeEach(() => {
    getJobQueryResponse = jest.fn();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('when page renders', () => {
    beforeEach(async () => {
      getJobQueryResponse.mockResolvedValue(mockJobResponse);
      await createComponentWithApollo();
    });

    it('renders help text with provided link', () => {
      expect(findHelpText().exists()).toBe(true);
      expect(findHelpLink().attributes('href')).toBe(
        '/help/ci/variables/index#add-a-cicd-variable-to-a-project',
      );
    });

    it('renders buttons', () => {
      expect(findCancelBtn().exists()).toBe(true);
      expect(findRerunBtn().exists()).toBe(true);
    });
  });

  describe('when job has variables', () => {
    beforeEach(async () => {
      getJobQueryResponse.mockResolvedValue(mockJobWithVariablesResponse);
      await createComponentWithApollo();
    });

    it('sets manual job variables', () => {
      const queryKey = mockJobWithVariablesResponse.data.project.job.manualVariables.nodes[0].key;
      const queryValue =
        mockJobWithVariablesResponse.data.project.job.manualVariables.nodes[0].value;

      expect(findCiVariableKey().element.value).toBe(queryKey);
      expect(findCiVariableValue().element.value).toBe(queryValue);
    });
  });

  describe('when mutation fires', () => {
    beforeEach(async () => {
      await createComponentWithApollo();
      jest.spyOn(wrapper.vm.$apollo, 'mutate').mockResolvedValue(mockJobMutationData);
    });

    it('passes variables in correct format', async () => {
      await setCiVariableKey();

      await findCiVariableValue().setValue('new value');

      await findRerunBtn().vm.$emit('click');

      expect(wrapper.vm.$apollo.mutate).toHaveBeenCalledTimes(1);
      expect(wrapper.vm.$apollo.mutate).toHaveBeenCalledWith({
        mutation: retryJobMutation,
        variables: {
          id: convertToGraphQLId(GRAPHQL_ID_TYPES.ciBuild, mockId),
          variables: [
            {
              key: 'new key',
              value: 'new value',
            },
          ],
        },
      });
    });
  });

  describe('updating variables in UI', () => {
    beforeEach(async () => {
      getJobQueryResponse.mockResolvedValue(mockJobResponse);
      await createComponentWithApollo();
    });

    it('creates a new variable when user enters a new key value', async () => {
      expect(findAllVariables()).toHaveLength(1);

      await setCiVariableKey();

      expect(findAllVariables()).toHaveLength(2);
    });

    it('does not create extra empty variables', async () => {
      expect(findAllVariables()).toHaveLength(1);

      await setCiVariableKey();

      expect(findAllVariables()).toHaveLength(2);

      await setCiVariableKey();

      expect(findAllVariables()).toHaveLength(2);
    });

    it('removes the correct variable row', async () => {
      const variableKeyNameOne = 'key-one';
      const variableKeyNameThree = 'key-three';

      await setCiVariableKeyByPosition(0, variableKeyNameOne);

      await setCiVariableKeyByPosition(1, 'key-two');

      await setCiVariableKeyByPosition(2, variableKeyNameThree);

      expect(findAllVariables()).toHaveLength(4);

      await findAllDeleteVarBtns().at(1).trigger('click');

      expect(findAllVariables()).toHaveLength(3);

      expect(findAllCiVariableKeys().at(0).element.value).toBe(variableKeyNameOne);
      expect(findAllCiVariableKeys().at(1).element.value).toBe(variableKeyNameThree);
      expect(findAllCiVariableKeys().at(2).element.value).toBe('');
    });

    it('delete variable button should only show when there is more than one variable', async () => {
      expect(findDeleteVarBtn().exists()).toBe(false);

      await setCiVariableKey();

      expect(findDeleteVarBtn().exists()).toBe(true);
    });
  });

  describe('variable delete button placeholder', () => {
    beforeEach(async () => {
      getJobQueryResponse.mockResolvedValue(mockJobResponse);
      await createComponentWithApollo();
    });

    it('delete variable button placeholder should only exist when a user cannot remove', async () => {
      expect(findDeleteVarBtnPlaceholder().exists()).toBe(true);
    });

    it('does not show the placeholder button', () => {
      expect(findDeleteVarBtnPlaceholder().classes('gl-opacity-0')).toBe(true);
    });

    it('placeholder button will not delete the row on click', async () => {
      expect(findAllCiVariableKeys()).toHaveLength(1);
      expect(findDeleteVarBtnPlaceholder().exists()).toBe(true);

      await findDeleteVarBtnPlaceholder().trigger('click');

      expect(findAllCiVariableKeys()).toHaveLength(1);
      expect(findDeleteVarBtnPlaceholder().exists()).toBe(true);
    });
  });
});
