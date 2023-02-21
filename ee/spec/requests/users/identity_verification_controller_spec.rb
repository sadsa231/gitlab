# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Users::IdentityVerificationController, :clean_gitlab_redis_sessions, :clean_gitlab_redis_rate_limiting,
feature_category: :authentication_and_authorization do
  include SessionHelpers

  let_it_be(:unconfirmed_user) { create(:user, :unconfirmed, :arkose_verified) }
  let_it_be(:confirmed_user) { create(:user, :arkose_verified) }

  shared_examples 'it requires an unconfirmed user' do
    before do
      stub_session(verification_user_id: user&.id)
      do_request
    end

    subject { response }

    context 'when session contains no `verification_user_id`' do
      let_it_be(:user) { nil }

      it { is_expected.to have_gitlab_http_status(:not_found) }
    end

    context 'when session contains a `verification_user_id` from a confirmed user' do
      let_it_be(:user) { confirmed_user }

      it { is_expected.to have_gitlab_http_status(:not_found) }
    end

    context 'when session contains a `verification_user_id` from an unconfirmed user' do
      let_it_be(:user) { unconfirmed_user }

      it { is_expected.to have_gitlab_http_status(:ok) }
    end
  end

  shared_examples 'it requires oauth users to go through ArkoseLabs challenge' do
    let(:user) { create(:omniauth_user, :unconfirmed) }
    let(:arkose_labs_oauth_signup_challenge) { true }

    before do
      stub_feature_flags(arkose_labs_oauth_signup_challenge: arkose_labs_oauth_signup_challenge)
      stub_session(verification_user_id: user.id)
      do_request
    end

    subject { response }

    it { is_expected.to redirect_to(arkose_labs_challenge_identity_verification_path) }

    context 'when arkose_labs_oauth_signup_challenge feature flag is disabled' do
      let(:arkose_labs_oauth_signup_challenge) { false }

      it { is_expected.not_to redirect_to(arkose_labs_challenge_identity_verification_path) }
    end

    context 'when user has an arkose_risk_band' do
      let(:user) { create(:omniauth_user, :unconfirmed, :arkose_verified) }

      it { is_expected.not_to redirect_to(arkose_labs_challenge_identity_verification_path) }
    end
  end

  describe '#show' do
    subject(:do_request) { get identity_verification_path }

    it_behaves_like 'it requires an unconfirmed user'
    it_behaves_like 'it requires oauth users to go through ArkoseLabs challenge'

    it 'renders template show with layout minimal' do
      stub_session(verification_user_id: unconfirmed_user.id)

      do_request

      expect(response).to render_template('show', layout: 'minimal')
    end
  end

  describe '#verify_email_code' do
    let_it_be(:params) { { identity_verification: { code: '123456' } } }
    let_it_be(:service_response) { { status: :success } }

    subject(:do_request) { post verify_email_code_identity_verification_path(params) }

    before do
      allow_next_instance_of(::Users::EmailVerification::ValidateTokenService) do |service|
        allow(service).to receive(:execute).and_return(service_response)
      end
    end

    it_behaves_like 'it requires an unconfirmed user'
    it_behaves_like 'it requires oauth users to go through ArkoseLabs challenge'

    context 'when validation was successful' do
      it 'confirms the user' do
        stub_session(verification_user_id: unconfirmed_user.id)

        freeze_time do
          expect { do_request }.to change { unconfirmed_user.reload.confirmed_at }.from(nil).to(Time.current)
        end
      end

      it 'accepts pending invitations' do
        member_invite = create(:project_member, :invited, invite_email: unconfirmed_user.email)
        stub_session(verification_user_id: unconfirmed_user.id)

        do_request

        expect(member_invite.reload).not_to be_invite
      end

      it 'signs in the user' do
        stub_session(verification_user_id: unconfirmed_user.id)

        do_request

        expect(request.env['warden']).to be_authenticated
      end

      it 'logs and tracks the successful attempt' do
        expect(Gitlab::AppLogger).to receive(:info).with(
          hash_including(
            message: 'IdentityVerification::Email',
            event: 'Success',
            username: unconfirmed_user.username
          )
        )

        stub_session(verification_user_id: unconfirmed_user.id)

        do_request

        expect_snowplow_event(
          category: 'IdentityVerification::Email',
          action: 'success',
          property: '',
          user: unconfirmed_user
        )
      end

      it 'renders the result as json including a redirect URL' do
        stub_session(verification_user_id: unconfirmed_user.id)

        do_request

        expect(response.body).to eq(service_response.merge(redirect_url: users_successful_verification_path).to_json)
      end
    end

    context 'when failing to validate' do
      let_it_be(:service_response) { { status: :failure, reason: 'reason', message: 'message' } }

      it 'logs and tracks the failed attempt' do
        expect(Gitlab::AppLogger).to receive(:info).with(
          hash_including(
            message: 'IdentityVerification::Email',
            event: 'Failed Attempt',
            username: unconfirmed_user.username,
            reason: service_response[:reason]
          )
        )

        stub_session(verification_user_id: unconfirmed_user.id)
        do_request

        expect_snowplow_event(
          category: 'IdentityVerification::Email',
          action: 'failed_attempt',
          property: service_response[:reason],
          user: unconfirmed_user
        )
      end

      it 'renders the result as json' do
        stub_session(verification_user_id: unconfirmed_user.id)

        do_request

        expect(response.body).to eq(service_response.to_json)
      end
    end
  end

  describe '#resend_email_code' do
    subject(:do_request) { post resend_email_code_identity_verification_path }

    it_behaves_like 'it requires an unconfirmed user'
    it_behaves_like 'it requires oauth users to go through ArkoseLabs challenge'

    context 'when rate limited' do
      before do
        allow(Gitlab::ApplicationRateLimiter).to receive(:throttled?)
          .with(:email_verification_code_send, scope: unconfirmed_user).and_return(true)
        stub_session(verification_user_id: unconfirmed_user.id)
        do_request
      end

      it 'renders the result as json' do
        expect(response.body).to eq({
          status: :failure,
          message: format(s_("IdentityVerification|You've reached the maximum amount of resends. Wait %{interval} "\
            'and try again.'), interval: 'about 1 hour')
        }.to_json)
      end
    end

    context 'when successful' do
      let_it_be(:new_token) { '123456' }
      let_it_be(:encrypted_token) { Devise.token_generator.digest(User, :confirmation_token, new_token) }

      before do
        allow_next_instance_of(::Users::EmailVerification::GenerateTokenService, attr: :confirmation_token) do |service|
          allow(service).to receive(:generate_token).and_return(new_token)
        end
        stub_session(verification_user_id: unconfirmed_user.id)
      end

      it 'sets the confirmation_sent_at time' do
        freeze_time do
          expect { do_request }.to change { unconfirmed_user.reload.confirmation_sent_at }.to(Time.current)
        end
      end

      it 'sets the confirmation_token to the encrypted custom token' do
        expect { do_request }.to change { unconfirmed_user.reload.confirmation_token }.to(encrypted_token)
      end

      it 'sends the confirmation instructions email' do
        expect(::Notify).to receive(:confirmation_instructions_email)
          .with(unconfirmed_user.email, token: new_token).once.and_call_original

        do_request
      end

      it 'logs and tracks resending the instructions' do
        expect(Gitlab::AppLogger).to receive(:info).with(
          hash_including(
            message: 'IdentityVerification::Email',
            event: 'Sent Instructions',
            username: unconfirmed_user.username
          )
        )

        do_request

        expect_snowplow_event(
          category: 'IdentityVerification::Email',
          action: 'sent_instructions',
          property: '',
          user: unconfirmed_user
        )
      end

      it 'renders the result as json' do
        do_request

        expect(response.body).to eq({ status: :success }.to_json)
      end
    end
  end

  describe '#send_phone_verification_code' do
    let_it_be(:service_response) { ServiceResponse.success }
    let_it_be(:params) do
      { identity_verification: { country: 'US', international_dial_code: '1', phone_number: '555' } }
    end

    subject(:do_request) { post send_phone_verification_code_identity_verification_path(params) }

    before do
      allow_next_instance_of(::PhoneVerification::Users::SendVerificationCodeService) do |service|
        allow(service).to receive(:execute).and_return(service_response)
      end
      stub_session(verification_user_id: unconfirmed_user.id)
    end

    it_behaves_like 'it requires an unconfirmed user'
    it_behaves_like 'it requires oauth users to go through ArkoseLabs challenge'

    context 'when sending the code is successful' do
      it 'responds with status 200 OK' do
        do_request

        expect(response.body).to eq({ status: :success }.to_json)
      end

      it 'logs and tracks the success attempt' do
        expect(Gitlab::AppLogger).to receive(:info).with(
          hash_including(
            message: 'IdentityVerification::Phone',
            event: 'Sent Phone Verification Code',
            username: unconfirmed_user.username
          )
        )

        do_request

        expect_snowplow_event(
          category: 'IdentityVerification::Phone',
          action: 'sent_phone_verification_code',
          property: '',
          user: unconfirmed_user
        )
      end
    end

    context 'when sending the code is unsuccessful' do
      let_it_be(:service_response) { ServiceResponse.error(message: 'message', reason: 'reason') }

      it 'logs and tracks the failed attempt' do
        expect(Gitlab::AppLogger).to receive(:info).with(
          hash_including(
            message: 'IdentityVerification::Phone',
            event: 'Failed Attempt',
            username: unconfirmed_user.username,
            reason: service_response.reason
          )
        )

        do_request

        expect_snowplow_event(
          category: 'IdentityVerification::Phone',
          action: 'failed_attempt',
          property: service_response[:reason],
          user: unconfirmed_user
        )
      end

      it 'responds with error message' do
        do_request

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(response.body).to eq({ message: service_response.message }.to_json)
      end
    end
  end

  describe '#verify_phone_verification_code' do
    let_it_be(:service_response) { ServiceResponse.success }
    let_it_be(:params) do
      { identity_verification: { verification_code: '999' } }
    end

    subject(:do_request) { post verify_phone_verification_code_identity_verification_path(params) }

    before do
      allow_next_instance_of(::PhoneVerification::Users::VerifyCodeService) do |service|
        allow(service).to receive(:execute).and_return(service_response)
      end
      stub_session(verification_user_id: unconfirmed_user.id)
    end

    it_behaves_like 'it requires an unconfirmed user'
    it_behaves_like 'it requires oauth users to go through ArkoseLabs challenge'

    context 'when sending the code is successful' do
      it 'responds with status 200 OK' do
        do_request

        expect(response.body).to eq({ status: :success }.to_json)
      end

      it 'logs and tracks the success attempt' do
        expect(Gitlab::AppLogger).to receive(:info).with(
          hash_including(
            message: 'IdentityVerification::Phone',
            event: 'Success',
            username: unconfirmed_user.username
          )
        )

        do_request

        expect_snowplow_event(
          category: 'IdentityVerification::Phone',
          action: 'success',
          property: '',
          user: unconfirmed_user
        )
      end
    end

    context 'when sending the code is unsuccessful' do
      let_it_be(:service_response) { ServiceResponse.error(message: 'message', reason: 'reason') }

      it 'logs and tracks the failed attempt' do
        expect(Gitlab::AppLogger).to receive(:info).with(
          hash_including(
            message: 'IdentityVerification::Phone',
            event: 'Failed Attempt',
            username: unconfirmed_user.username,
            reason: service_response.reason
          )
        )

        do_request

        expect_snowplow_event(
          category: 'IdentityVerification::Phone',
          action: 'failed_attempt',
          property: service_response[:reason],
          user: unconfirmed_user
        )
      end

      it 'responds with error message' do
        do_request

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(response.body).to eq({ message: service_response.message }.to_json)
      end
    end
  end

  shared_examples 'it requires a user without an arkose risk_band' do
    let_it_be(:user_without_risk_band) { create(:user) }
    let_it_be(:user_with_risk_band) { create(:user) }

    let(:arkose_labs_oauth_signup_challenge) { true }

    before do
      stub_feature_flags(arkose_labs_oauth_signup_challenge: arkose_labs_oauth_signup_challenge)

      stub_session(verification_user_id: user&.id)
      request
    end

    subject { response }

    context 'when arkose_labs_oauth_signup_challenge feature flag is disabled' do
      let(:arkose_labs_oauth_signup_challenge) { false }

      it { is_expected.to have_gitlab_http_status(:not_found) }
    end

    context 'when session contains no `verification_user_id`' do
      let(:user) { nil }

      it { is_expected.to have_gitlab_http_status(:not_found) }
    end

    context 'when session contains a `verification_user_id` from a user with an arkose risk_band' do
      let(:user) { user_with_risk_band }

      it { is_expected.to have_gitlab_http_status(:not_found) }
    end

    context 'when session contains a `verification_user_id` from a user without an arkose risk_band' do
      let(:user) { user_without_risk_band }

      it { is_expected.to have_gitlab_http_status(:ok) }
    end
  end

  describe 'POST verify_arkose_labs_session' do
    let_it_be(:user) { create(:user, :unconfirmed, :arkose_verified) }

    let(:params) { {} }
    let(:do_request) { post verify_arkose_labs_session_identity_verification_path, params: params }

    it_behaves_like 'it requires an unconfirmed user'

    shared_examples 'renders arkose_labs_challenge with the correct alert flash' do
      it 'renders arkose_labs_challenge with the correct alert flash' do
        expect(flash[:alert]).to include(_('IdentityVerification|Complete verification to sign in.'))
        expect(response).to render_template('arkose_labs_challenge')
      end
    end

    context 'when arkose_labs_token param is not present' do
      before do
        stub_session(verification_user_id: user.id)
        do_request
      end

      it_behaves_like 'renders arkose_labs_challenge with the correct alert flash'
    end

    context 'when arkose_labs_token param is present' do
      let(:params) { { arkose_labs_token: 'fake-token' } }

      before do
        stub_session(verification_user_id: user.id)

        init_params = { session_token: params[:arkose_labs_token], user: user }
        allow_next_instance_of(Arkose::TokenVerificationService, init_params) do |instance|
          allow(instance).to receive(:execute).and_return(service_response)
        end

        do_request
      end

      context 'when token verification fails' do
        let(:service_response) { ServiceResponse.error(message: 'Captcha was not solved') }

        it_behaves_like 'renders arkose_labs_challenge with the correct alert flash'
      end

      context 'when token verification succeeds' do
        let(:service_response) { ServiceResponse.success }

        it 'redirects to show action' do
          expect(response).to redirect_to(identity_verification_path)
        end
      end
    end
  end

  describe 'GET arkose_labs_challenge' do
    let_it_be(:user) { create(:user, :unconfirmed) }

    let(:do_request) { get arkose_labs_challenge_identity_verification_path }

    it_behaves_like 'it requires an unconfirmed user'

    it 'renders arkose_labs_challenge template' do
      stub_session(verification_user_id: user.id)
      do_request

      expect(response).to render_template('arkose_labs_challenge', layout: 'minimal')
    end
  end
end
