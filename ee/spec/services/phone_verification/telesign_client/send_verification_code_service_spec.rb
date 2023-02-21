# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PhoneVerification::TelesignClient::SendVerificationCodeService do
  let(:telesign_customer_xid) { 'foo' }
  let(:telesign_api_key) { 'bar' }

  let(:user) { build(:user) }
  let(:phone_number) { '555' }
  let(:sms_template) { described_class::SMS_TEMPLATE }
  let(:telesign_reference_xid) { '360F69274E0813049191FB5A94308801' }

  subject(:service) { described_class.new(phone_number: phone_number, user: user) }

  before do
    allow_next_instance_of(TelesignEnterprise::VerifyClient) do |instance|
      allow(instance).to receive(:sms).and_return(telesign_response)
    end
  end

  describe '#execute', :aggregate_failures do
    context 'when verification code is sent successfully' do
      let(:telesign_response) do
        instance_double(
          Telesign::RestClient::Response,
          json: {
            'reference_id' => telesign_reference_xid
          },
          status_code: '200'
        )
      end

      it 'returns a success ServiceResponse' do
        response = service.execute

        expect(response).to be_a(ServiceResponse)
        expect(response).to be_success
        expect(response.payload).to eq({ telesign_reference_xid: telesign_reference_xid })
      end

      it 'logs an info message' do
        expect(::Gitlab::AppJsonLogger)
          .to receive(:info)
          .with(
            message: 'Sent a phone verification code with Telesign',
            telesign_response: telesign_response.json,
            telesign_status_code: telesign_response.status_code,
            user_id: user.id
          )
          .and_call_original

        service.execute
      end
    end

    context 'when phone number has invalid formatting' do
      let(:phone_number) { '1300 111 111' }
      let(:exception) { URI::InvalidURIError.new('invalid uri') }

      before do
        allow_next_instance_of(TelesignEnterprise::VerifyClient) do |instance|
          allow(instance).to receive(:sms).and_raise(exception)
        end
      end

      it 'returns an error ServiceResponse' do
        response = service.execute

        expect(response).to be_a(ServiceResponse)
        expect(response).to be_error
        expect(response.message).to eq(
          'There was a problem with the phone number you entered. '\
          'Enter a valid phone number.'
        )
        expect(response.reason).to eq(:invalid_phone_number)
      end
    end

    context 'when phone number does not exist' do
      let(:telesign_response) do
        instance_double(
          Telesign::RestClient::Response,
          json: {
            'errors' => [
              { 'code' => -10001, 'description' => 'Invalid Request: PhoneNumber Parameter' }
            ]
          },
          status_code: '400'
        )
      end

      it 'returns an error ServiceResponse' do
        response = service.execute

        expect(response).to be_a(ServiceResponse)
        expect(response).to be_error
        expect(response.message).to eq(
          'There was a problem with the phone number you entered. '\
          'Enter a valid phone number.'
        )
        expect(response.reason).to be(:invalid_phone_number)
      end
    end

    context 'when there is a server error' do
      let(:telesign_response) do
        instance_double(
          Telesign::RestClient::Response,
          json: {
            'errors' => [
              { 'code' => -40008, 'description' => 'Transaction not attempted' }
            ]
          },
          status_code: '500'
        )
      end

      it 'returns an error ServiceResponse' do
        response = service.execute

        expect(response).to be_a(ServiceResponse)
        expect(response).to be_error
        expect(response.message).to eq('Something went wrong. Please try again.')
        expect(response.reason).to be(:internal_server_error)
      end
    end

    context 'when there is an unknown exception' do
      let(:exception) { StandardError.new }

      before do
        allow(Gitlab::ErrorTracking).to receive(:track_exception)
        allow_next_instance_of(TelesignEnterprise::VerifyClient) do |instance|
          allow(instance).to receive(:sms).and_raise(exception)
        end
      end

      it 'returns an error ServiceResponse' do
        response = service.execute

        expect(response).to be_a(ServiceResponse)
        expect(response).to be_error
        expect(response.message).to eq('Something went wrong. Please try again.')
        expect(response.reason).to be(:internal_server_error)
      end

      it 'tracks the exception' do
        service.execute

        expect(Gitlab::ErrorTracking).to have_received(:track_exception).with(
          exception, user_id: user.id
        )
      end
    end
  end
end
