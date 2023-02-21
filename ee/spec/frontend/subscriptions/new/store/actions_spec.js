import MockAdapter from 'axios-mock-adapter';
import Api from 'ee/api';
import * as constants from 'ee/subscriptions/constants';
import defaultClient from 'ee/subscriptions/new/graphql';
import * as actions from 'ee/subscriptions/new/store/actions';
import { GENERAL_ERROR_MESSAGE } from 'ee/vue_shared/purchase_flow/constants';
import activateNextStepMutation from 'ee/vue_shared/purchase_flow/graphql/mutations/activate_next_step.mutation.graphql';
import { useMockLocationHelper } from 'helpers/mock_window_location_helper';
import testAction from 'helpers/vuex_action_helper';
import Tracking from '~/tracking';
import { createAlert } from '~/flash';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_INTERNAL_SERVER_ERROR, HTTP_STATUS_OK } from '~/lib/utils/http_status';
import * as googleTagManager from '~/google_tag_manager';

const {
  countriesPath,
  countryStatesPath,
  paymentFormPath,
  paymentMethodPath,
  confirmOrderPath,
} = Api;

jest.mock('~/flash');

describe('Subscriptions Actions', () => {
  let mock;

  beforeEach(() => {
    mock = new MockAdapter(axios);
    jest.spyOn(defaultClient, 'mutate');
  });

  afterEach(() => {
    mock.restore();
    defaultClient.mutate.mockClear();
  });

  describe('updateSelectedPlan', () => {
    it('updates the selected plan and updates the number of users', async () => {
      await testAction(
        actions.updateSelectedPlan,
        'planId',
        {},
        [{ type: 'UPDATE_SELECTED_PLAN', payload: 'planId' }],
        [],
      );
    });
  });

  describe('updateSelectedGroup', () => {
    it('updates the selected group, resets the organization name and updates the number of users', async () => {
      await testAction(
        actions.updateSelectedGroup,
        'groupId',
        {},
        [
          { type: 'UPDATE_SELECTED_GROUP', payload: 'groupId' },
          { type: 'UPDATE_ORGANIZATION_NAME', payload: null },
        ],
        [],
      );
    });
  });

  describe('toggleIsSetupForCompany', () => {
    it('toggles the isSetupForCompany value', async () => {
      await testAction(
        actions.toggleIsSetupForCompany,
        {},
        { isSetupForCompany: true },
        [{ type: 'UPDATE_IS_SETUP_FOR_COMPANY', payload: false }],
        [],
      );
    });
  });

  describe('updateNumberOfUsers', () => {
    it('updates numberOfUsers to 0 when no value is provided', async () => {
      await testAction(
        actions.updateNumberOfUsers,
        null,
        {},
        [{ type: 'UPDATE_NUMBER_OF_USERS', payload: 0 }],
        [],
      );
    });

    it('updates numberOfUsers when a value is provided', async () => {
      await testAction(
        actions.updateNumberOfUsers,
        2,
        {},
        [{ type: 'UPDATE_NUMBER_OF_USERS', payload: 2 }],
        [],
      );
    });
  });

  describe('updateOrganizationName', () => {
    it('updates organizationName to the provided value', async () => {
      await testAction(
        actions.updateOrganizationName,
        'name',
        {},
        [{ type: 'UPDATE_ORGANIZATION_NAME', payload: 'name' }],
        [],
      );
    });
  });

  describe('fetchCountries', () => {
    it('calls fetchCountriesSuccess with the returned data on success', async () => {
      mock.onGet(countriesPath).replyOnce(HTTP_STATUS_OK, ['Netherlands', 'NL']);

      await testAction(
        actions.fetchCountries,
        null,
        {},
        [],
        [{ type: 'fetchCountriesSuccess', payload: ['Netherlands', 'NL'] }],
      );
    });

    it('calls fetchCountriesError on error', async () => {
      mock.onGet(countriesPath).replyOnce(HTTP_STATUS_INTERNAL_SERVER_ERROR);

      await testAction(actions.fetchCountries, null, {}, [], [{ type: 'fetchCountriesError' }]);
    });
  });

  describe('fetchCountriesSuccess', () => {
    it('transforms and adds fetched countryOptions', async () => {
      await testAction(
        actions.fetchCountriesSuccess,
        [['Netherlands', 'NL']],
        {},
        [{ type: 'UPDATE_COUNTRY_OPTIONS', payload: [{ text: 'Netherlands', value: 'NL' }] }],
        [],
      );
    });

    it('adds an empty array when no data provided', async () => {
      await testAction(
        actions.fetchCountriesSuccess,
        undefined,
        {},
        [{ type: 'UPDATE_COUNTRY_OPTIONS', payload: [] }],
        [],
      );
    });
  });

  describe('fetchCountriesError', () => {
    it('creates a flash', async () => {
      await testAction(actions.fetchCountriesError, null, {}, [], []);
      expect(createAlert).toHaveBeenCalledWith({
        message: 'Failed to load countries. Please try again.',
      });
    });
  });

  describe('fetchStates', () => {
    it('calls resetStates and fetchStatesSuccess with the returned data on success', async () => {
      mock
        .onGet(countryStatesPath, { params: { country: 'NL' } })
        .replyOnce(HTTP_STATUS_OK, { utrecht: 'UT' });

      await testAction(
        actions.fetchStates,
        null,
        { country: 'NL' },
        [],
        [{ type: 'resetStates' }, { type: 'fetchStatesSuccess', payload: { utrecht: 'UT' } }],
      );
    });

    it('only calls resetStates when no country selected', async () => {
      mock.onGet(countryStatesPath).replyOnce(HTTP_STATUS_INTERNAL_SERVER_ERROR);

      await testAction(actions.fetchStates, null, { country: null }, [], [{ type: 'resetStates' }]);
    });

    it('calls resetStates and fetchStatesError on error', async () => {
      mock.onGet(countryStatesPath).replyOnce(HTTP_STATUS_INTERNAL_SERVER_ERROR);

      await testAction(
        actions.fetchStates,
        null,
        { country: 'NL' },
        [],
        [{ type: 'resetStates' }, { type: 'fetchStatesError' }],
      );
    });
  });

  describe('fetchStatesSuccess', () => {
    it('transforms and adds received stateOptions', async () => {
      await testAction(
        actions.fetchStatesSuccess,
        { Utrecht: 'UT' },
        {},
        [{ type: 'UPDATE_STATE_OPTIONS', payload: [{ text: 'Utrecht', value: 'UT' }] }],
        [],
      );
    });

    it('adds an empty array when no data provided', async () => {
      await testAction(
        actions.fetchStatesSuccess,
        undefined,
        {},
        [{ type: 'UPDATE_STATE_OPTIONS', payload: [] }],
        [],
      );
    });
  });

  describe('fetchStatesError', () => {
    it('creates a flash', async () => {
      await testAction(actions.fetchStatesError, null, {}, [], []);
      expect(createAlert).toHaveBeenCalledWith({
        message: 'Failed to load states. Please try again.',
      });
    });
  });

  describe('resetStates', () => {
    it('resets the selected state and sets the stateOptions to the initial value', async () => {
      await testAction(
        actions.resetStates,
        null,
        {},
        [
          { type: 'UPDATE_COUNTRY_STATE', payload: null },
          { type: 'UPDATE_STATE_OPTIONS', payload: [] },
        ],
        [],
      );
    });
  });

  describe('updateCountry', () => {
    it('updates country to the provided value', async () => {
      await testAction(
        actions.updateCountry,
        'country',
        {},
        [{ type: 'UPDATE_COUNTRY', payload: 'country' }],
        [],
      );
    });
  });

  describe('updateStreetAddressLine1', () => {
    it('updates streetAddressLine1 to the provided value', async () => {
      await testAction(
        actions.updateStreetAddressLine1,
        'streetAddressLine1',
        {},
        [{ type: 'UPDATE_STREET_ADDRESS_LINE_ONE', payload: 'streetAddressLine1' }],
        [],
      );
    });
  });

  describe('updateStreetAddressLine2', () => {
    it('updates streetAddressLine2 to the provided value', async () => {
      await testAction(
        actions.updateStreetAddressLine2,
        'streetAddressLine2',
        {},
        [{ type: 'UPDATE_STREET_ADDRESS_LINE_TWO', payload: 'streetAddressLine2' }],
        [],
      );
    });
  });

  describe('updateCity', () => {
    it('updates city to the provided value', async () => {
      await testAction(
        actions.updateCity,
        'city',
        {},
        [{ type: 'UPDATE_CITY', payload: 'city' }],
        [],
      );
    });
  });

  describe('updateCountryState', () => {
    it('updates countryState to the provided value', async () => {
      await testAction(
        actions.updateCountryState,
        'countryState',
        {},
        [{ type: 'UPDATE_COUNTRY_STATE', payload: 'countryState' }],
        [],
      );
    });
  });

  describe('updateZipCode', () => {
    it('updates zipCode to the provided value', async () => {
      await testAction(
        actions.updateZipCode,
        'zipCode',
        {},
        [{ type: 'UPDATE_ZIP_CODE', payload: 'zipCode' }],
        [],
      );
    });
  });

  describe('startLoadingZuoraScript', () => {
    it('updates isLoadingPaymentMethod to true', async () => {
      await testAction(
        actions.startLoadingZuoraScript,
        undefined,
        {},
        [{ type: 'UPDATE_IS_LOADING_PAYMENT_METHOD', payload: true }],
        [],
      );
    });
  });

  describe('fetchPaymentFormParams', () => {
    it('fetches paymentFormParams and calls fetchPaymentFormParamsSuccess with the returned data on success', async () => {
      mock
        .onGet(paymentFormPath, { params: { id: constants.PAYMENT_FORM_ID } })
        .replyOnce(HTTP_STATUS_OK, { token: 'x' });

      await testAction(
        actions.fetchPaymentFormParams,
        null,
        {},
        [],
        [{ type: 'fetchPaymentFormParamsSuccess', payload: { token: 'x' } }],
      );
    });

    it('calls fetchPaymentFormParamsError on error', async () => {
      mock.onGet(paymentFormPath).replyOnce(HTTP_STATUS_INTERNAL_SERVER_ERROR);

      await testAction(
        actions.fetchPaymentFormParams,
        null,
        {},
        [],
        [{ type: 'fetchPaymentFormParamsError' }],
      );
    });
  });

  describe('fetchPaymentFormParamsSuccess', () => {
    it('updates paymentFormParams to the provided value when no errors are present', async () => {
      await testAction(
        actions.fetchPaymentFormParamsSuccess,
        { token: 'x' },
        {},
        [{ type: 'UPDATE_PAYMENT_FORM_PARAMS', payload: { token: 'x' } }],
        [],
      );
    });

    it('creates a flash when errors are present', async () => {
      await testAction(
        actions.fetchPaymentFormParamsSuccess,
        { errors: 'error message' },
        {},
        [],
        [],
      );
      expect(createAlert).toHaveBeenCalledWith({
        message: 'Credit card form failed to load: error message',
      });
    });
  });

  describe('fetchPaymentFormParamsError', () => {
    it('creates a flash', async () => {
      await testAction(actions.fetchPaymentFormParamsError, null, {}, [], []);
      expect(createAlert).toHaveBeenCalledWith({
        message: 'Credit card form failed to load. Please try again.',
      });
    });
  });

  describe('zuoraIframeRendered', () => {
    it('updates isLoadingPaymentMethod to false', async () => {
      await testAction(
        actions.zuoraIframeRendered,
        undefined,
        {},
        [{ type: 'UPDATE_IS_LOADING_PAYMENT_METHOD', payload: false }],
        [],
      );
    });
  });

  describe('paymentFormSubmitted', () => {
    describe('on success', () => {
      it('calls paymentFormSubmittedSuccess with the refID from the response and updates isLoadingPaymentMethod to true', async () => {
        await testAction(
          actions.paymentFormSubmitted,
          { success: true, refId: 'id' },
          {},
          [{ type: 'UPDATE_IS_LOADING_PAYMENT_METHOD', payload: true }],
          [{ type: 'paymentFormSubmittedSuccess', payload: 'id' }],
        );
      });
    });

    describe('on failure', () => {
      it('calls paymentFormSubmittedError with the response', async () => {
        await testAction(
          actions.paymentFormSubmitted,
          { error: 'foo' },
          {},
          [],
          [{ type: 'paymentFormSubmittedError', payload: { error: 'foo' } }],
        );
      });
    });
  });

  describe('paymentFormSubmittedSuccess', () => {
    it('updates paymentMethodId to the provided value and calls fetchPaymentMethodDetails', async () => {
      await testAction(
        actions.paymentFormSubmittedSuccess,
        'id',
        {},
        [{ type: 'UPDATE_PAYMENT_METHOD_ID', payload: 'id' }],
        [{ type: 'fetchPaymentMethodDetails' }],
      );
    });
  });

  describe('paymentFormSubmittedError', () => {
    it('creates a flash', async () => {
      await testAction(
        actions.paymentFormSubmittedError,
        { errorCode: 'codeFromResponse', errorMessage: 'messageFromResponse' },
        {},
        [],
        [],
      );
      expect(createAlert).toHaveBeenCalledWith({
        message:
          'Submitting the credit card form failed with code codeFromResponse: messageFromResponse',
      });
    });
  });

  describe('fetchPaymentMethodDetails', () => {
    it('fetches paymentMethodDetails and calls fetchPaymentMethodDetailsSuccess with the returned data on success and updates isLoadingPaymentMethod to false', async () => {
      mock
        .onGet(paymentMethodPath, { params: { id: 'paymentMethodId' } })
        .replyOnce(HTTP_STATUS_OK, { token: 'x' });

      await testAction(
        actions.fetchPaymentMethodDetails,
        null,
        { paymentMethodId: 'paymentMethodId' },
        [{ type: 'UPDATE_IS_LOADING_PAYMENT_METHOD', payload: false }],
        [{ type: 'fetchPaymentMethodDetailsSuccess', payload: { token: 'x' } }],
      );
    });

    it('calls fetchPaymentMethodDetailsError on error and updates isLoadingPaymentMethod to false', async () => {
      mock.onGet(paymentMethodPath).replyOnce(HTTP_STATUS_INTERNAL_SERVER_ERROR);

      await testAction(
        actions.fetchPaymentMethodDetails,
        null,
        {},
        [{ type: 'UPDATE_IS_LOADING_PAYMENT_METHOD', payload: false }],
        [{ type: 'fetchPaymentMethodDetailsError' }],
      );
    });
  });

  describe('fetchPaymentMethodDetailsSuccess', () => {
    const creditCardDetails = {
      credit_card_type: 'cc_type',
      credit_card_mask_number: '************4242',
      credit_card_expiration_month: 12,
      credit_card_expiration_year: 2019,
    };

    it('updates creditCardDetails to the provided data and calls defaultClient with activateNextStepMutation', async () => {
      await testAction(
        actions.fetchPaymentMethodDetailsSuccess,
        creditCardDetails,
        {},
        [
          {
            type: 'UPDATE_CREDIT_CARD_DETAILS',
            payload: creditCardDetails,
          },
        ],
        [],
      );
      expect(defaultClient.mutate).toHaveBeenCalledWith({
        mutation: activateNextStepMutation,
      });
    });

    it('displays an error if activateNextStepMutation fails', async () => {
      const error = new Error('An error happened!');
      jest.spyOn(defaultClient, 'mutate').mockRejectedValue(error);
      await testAction(
        actions.fetchPaymentMethodDetailsSuccess,
        creditCardDetails,
        {},
        [
          {
            type: 'UPDATE_CREDIT_CARD_DETAILS',
            payload: creditCardDetails,
          },
        ],
        [],
      );
      expect(createAlert).toHaveBeenCalledWith({
        message: GENERAL_ERROR_MESSAGE,
        error,
        captureError: true,
      });
    });
  });

  describe('fetchPaymentMethodDetailsError', () => {
    it('creates a flash', async () => {
      await testAction(actions.fetchPaymentMethodDetailsError, null, {}, [], []);
      expect(createAlert).toHaveBeenCalledWith({
        message: 'Failed to register credit card. Please try again.',
      });
    });
  });

  describe('confirmOrder', () => {
    describe('on success', () => {
      const payload = { location: 'x' };

      beforeEach(() => mock.onPost(confirmOrderPath).replyOnce(HTTP_STATUS_OK, payload));

      it('calls trackTransaction', async () => {
        const spy = jest.spyOn(googleTagManager, 'trackTransaction');

        await testAction(
          actions.confirmOrder,
          null,
          {},
          [{ type: 'UPDATE_IS_CONFIRMING_ORDER', payload: true }],
          [{ type: 'confirmOrderSuccess', payload }],
        );

        expect(spy).toHaveBeenCalled();
      });

      it('calls tracking event', async () => {
        const spy = jest.spyOn(Tracking, 'event');

        await testAction(
          actions.confirmOrder,
          null,
          {},
          [{ type: 'UPDATE_IS_CONFIRMING_ORDER', payload: true }],
          [{ type: 'confirmOrderSuccess', payload }],
        );

        expect(spy).toHaveBeenCalledWith('default', 'click_button', {
          label: 'confirm_purchase',
          property: 'Success: subscription',
        });
      });
    });

    describe('on error', () => {
      it('calls tracking event', async () => {
        const errors = 'errors';
        const spy = jest.spyOn(Tracking, 'event');

        mock.onPost(confirmOrderPath).replyOnce(HTTP_STATUS_OK, { errors });

        await testAction(
          actions.confirmOrder,
          null,
          {},
          [{ type: 'UPDATE_IS_CONFIRMING_ORDER', payload: true }],
          [{ type: 'confirmOrderError', payload: '"errors"' }],
        );

        expect(spy).toHaveBeenCalledWith('default', 'click_button', {
          label: 'confirm_purchase',
          property: errors,
        });
      });

      it('calls confirmOrderError with the returned group name error', async () => {
        mock.onPost(confirmOrderPath).replyOnce(HTTP_STATUS_OK, { name: ['Error_1', "Error ' 2"] });

        await testAction(
          actions.confirmOrder,
          null,
          {},
          [{ type: 'UPDATE_IS_CONFIRMING_ORDER', payload: true }],
          [{ type: 'confirmOrderError', payload: '"Name: Error_1, Error \' 2"' }],
        );
      });
    });

    describe('on failure', () => {
      beforeEach(() => mock.onPost(confirmOrderPath).replyOnce(HTTP_STATUS_INTERNAL_SERVER_ERROR));

      it('calls tracking event', async () => {
        const spy = jest.spyOn(Tracking, 'event');

        await testAction(
          actions.confirmOrder,
          null,
          {},
          [{ type: 'UPDATE_IS_CONFIRMING_ORDER', payload: true }],
          [{ type: 'confirmOrderError' }],
        );

        expect(spy).toHaveBeenCalledWith('default', 'click_button', {
          label: 'confirm_purchase',
          property: 'Request failed with status code 500',
        });
      });
    });
  });

  describe('confirmOrderSuccess', () => {
    useMockLocationHelper();

    const params = { location: 'http://example.com', plan_id: 'x', quantity: 10 };

    it('changes the window location', async () => {
      await testAction(actions.confirmOrderSuccess, params, {}, [], []);
      expect(window.location.assign).toHaveBeenCalledWith('http://example.com');
    });
  });

  describe('confirmOrderError', () => {
    it('creates a flash with a default message when no error given', async () => {
      await testAction(
        actions.confirmOrderError,
        null,
        {},
        [{ type: 'UPDATE_IS_CONFIRMING_ORDER', payload: false }],
        [],
      );
      expect(createAlert).toHaveBeenCalledWith({
        message: 'Failed to confirm your order! Please try again.',
      });
    });

    it('creates a flash with a the error message when an error is given', async () => {
      await testAction(
        actions.confirmOrderError,
        '"Error"',
        {},
        [{ type: 'UPDATE_IS_CONFIRMING_ORDER', payload: false }],
        [],
      );
      expect(createAlert).toHaveBeenCalledWith({
        message: 'Failed to confirm your order: "Error". Please try again.',
      });
    });
  });
});