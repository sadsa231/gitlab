# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PersonalAccessToken, feature_category: :authentication_and_authorization do
  subject { described_class }

  describe '.build' do
    let(:personal_access_token) { build(:personal_access_token) }
    let(:invalid_personal_access_token) { build(:personal_access_token, :invalid) }

    it 'is a valid personal access token' do
      expect(personal_access_token).to be_valid
    end

    it 'ensures that the token is generated' do
      invalid_personal_access_token.save!

      expect(invalid_personal_access_token).to be_valid
      expect(invalid_personal_access_token.token).not_to be_nil
    end
  end

  describe 'scopes' do
    describe '.project_access_tokens' do
      let_it_be(:user) { create(:user, :project_bot) }
      let_it_be(:project_member) { create(:project_member, user: user) }
      let_it_be(:project_access_token) { create(:personal_access_token, user: user) }

      subject { described_class.project_access_token }

      it { is_expected.to contain_exactly(project_access_token) }
    end

    describe '.owner_is_human' do
      let_it_be(:user) { create(:user, :project_bot) }
      let_it_be(:project_member) { create(:project_member, user: user) }
      let_it_be(:personal_access_token) { create(:personal_access_token) }
      let_it_be(:project_access_token) { create(:personal_access_token, user: user) }

      subject { described_class.owner_is_human }

      it { is_expected.to contain_exactly(personal_access_token) }
    end

    describe '.for_user' do
      it 'returns personal access tokens of specified user only' do
        user_1 = create(:user)
        token_of_user_1 = create(:personal_access_token, user: user_1)
        create_list(:personal_access_token, 2)

        expect(described_class.for_user(user_1)).to contain_exactly(token_of_user_1)
      end
    end

    describe '.for_users' do
      it 'returns personal access tokens for the specified users only' do
        user_1 = create(:user)
        user_2 = create(:user)
        token_of_user_1 = create(:personal_access_token, user: user_1)
        token_of_user_2 = create(:personal_access_token, user: user_2)
        create_list(:personal_access_token, 3)

        expect(described_class.for_users([user_1, user_2])).to contain_exactly(token_of_user_1, token_of_user_2)
      end
    end

    describe '.created_before' do
      let(:last_used_at) { 1.month.ago.beginning_of_hour }
      let!(:new_used_token) do
        create(:personal_access_token,
          created_at: last_used_at + 1.minute,
          last_used_at: last_used_at + 1.minute
        )
      end

      let!(:old_unused_token) do
        create(:personal_access_token,
          created_at: last_used_at - 1.minute
        )
      end

      let!(:old_formerly_used_token) do
        create(:personal_access_token,
          created_at: last_used_at - 1.minute,
          last_used_at: last_used_at - 1.minute
        )
      end

      let!(:old_still_used_token) do
        create(:personal_access_token,
          created_at: last_used_at - 1.minute,
          last_used_at: 1.minute.ago
        )
      end

      subject { described_class.created_before(last_used_at) }

      it do
        is_expected.to contain_exactly(
          old_unused_token,
          old_formerly_used_token,
          old_still_used_token
        )
      end
    end

    describe '.last_used_before' do
      context 'last_used_*' do
        let_it_be(:date) { DateTime.new(2022, 01, 01) }
        let_it_be(:token) { create(:personal_access_token, last_used_at: date) }
        # This token should never occur in the following tests and indicates that filtering was done correctly with it
        let_it_be(:never_used_token) { create(:personal_access_token) }

        describe '.last_used_before' do
          it 'returns personal access tokens used before the specified date only' do
            expect(described_class.last_used_before(date + 1)).to contain_exactly(token)
          end
        end

        it 'does not return token that is last_used_at after given date' do
          expect(described_class.last_used_before(date + 1)).not_to contain_exactly(never_used_token)
        end

        describe '.last_used_after' do
          it 'returns personal access tokens used after the specified date only' do
            expect(described_class.last_used_after(date - 1)).to contain_exactly(token)
          end
        end
      end
    end

    describe '.last_used_before_or_unused' do
      let(:last_used_at) { 1.month.ago.beginning_of_hour }
      let!(:unused_token)  { create(:personal_access_token) }
      let!(:used_token) do
        create(:personal_access_token,
          created_at: last_used_at + 1.minute,
          last_used_at: last_used_at + 1.minute
        )
      end

      let!(:old_unused_token) do
        create(:personal_access_token,
          created_at: last_used_at - 1.minute
        )
      end

      let!(:old_formerly_used_token) do
        create(:personal_access_token,
          created_at: last_used_at - 1.minute,
          last_used_at: last_used_at - 1.minute
        )
      end

      let!(:old_still_used_token) do
        create(:personal_access_token,
          created_at: last_used_at - 1.minute,
          last_used_at: 1.minute.ago
        )
      end

      subject { described_class.last_used_before_or_unused(last_used_at) }

      it { is_expected.to contain_exactly(old_unused_token, old_formerly_used_token) }
    end
  end

  describe ".active?" do
    let(:active_personal_access_token) { build(:personal_access_token) }
    let(:revoked_personal_access_token) { build(:personal_access_token, :revoked) }
    let(:expired_personal_access_token) { build(:personal_access_token, :expired) }

    it "returns false if the personal_access_token is revoked" do
      expect(revoked_personal_access_token).not_to be_active
    end

    it "returns false if the personal_access_token is expired" do
      expect(expired_personal_access_token).not_to be_active
    end

    it "returns true if the personal_access_token is not revoked and not expired" do
      expect(active_personal_access_token).to be_active
    end
  end

  describe 'revoke!' do
    let(:active_personal_access_token) { create(:personal_access_token) }

    it 'revokes the token' do
      active_personal_access_token.revoke!

      expect(active_personal_access_token).to be_revoked
    end
  end

  context "validations" do
    let(:personal_access_token) { build(:personal_access_token) }

    it "requires at least one scope" do
      personal_access_token.scopes = []

      expect(personal_access_token).not_to be_valid
      expect(personal_access_token.errors[:scopes].first).to eq "can't be blank"
    end

    it "allows creating a token with API scopes" do
      personal_access_token.scopes = [:api, :read_user]

      expect(personal_access_token).to be_valid
    end

    it "allows creating a token with `admin_mode` scope" do
      personal_access_token.scopes = [:api, :admin_mode]

      expect(personal_access_token).to be_valid
    end

    context 'with feature flag disabled' do
      before do
        stub_feature_flags(admin_mode_for_api: false)
      end

      it "allows creating a token with `admin_mode` scope" do
        personal_access_token.scopes = [:api, :admin_mode]

        expect(personal_access_token).to be_valid
      end
    end

    context 'when registry is disabled' do
      before do
        stub_container_registry_config(enabled: false)
      end

      it "rejects creating a token with read_registry scope" do
        personal_access_token.scopes = [:read_registry]

        expect(personal_access_token).not_to be_valid
        expect(personal_access_token.errors[:scopes].first).to eq "can only contain available scopes"
      end

      it "allows revoking a token with read_registry scope" do
        personal_access_token.scopes = [:read_registry]

        personal_access_token.revoke!

        expect(personal_access_token).to be_revoked
      end
    end

    context 'when registry is enabled' do
      before do
        stub_container_registry_config(enabled: true)
      end

      it "allows creating a token with read_registry scope" do
        personal_access_token.scopes = [:read_registry]

        expect(personal_access_token).to be_valid
      end
    end

    it "rejects creating a token with unavailable scopes" do
      personal_access_token.scopes = [:openid, :api]

      expect(personal_access_token).not_to be_valid
      expect(personal_access_token.errors[:scopes].first).to eq "can only contain available scopes"
    end
  end

  describe 'scopes' do
    describe '.active' do
      let_it_be(:revoked_token) { create(:personal_access_token, :revoked) }
      let_it_be(:not_revoked_false_token) { create(:personal_access_token, revoked: false) }
      let_it_be(:not_revoked_nil_token) { create(:personal_access_token, revoked: nil) }
      let_it_be(:expired_token) { create(:personal_access_token, :expired) }
      let_it_be(:not_expired_token) { create(:personal_access_token) }
      let_it_be(:never_expires_token) { create(:personal_access_token, expires_at: nil) }

      it 'includes non-revoked and non-expired tokens' do
        expect(described_class.active)
          .to match_array([not_revoked_false_token, not_revoked_nil_token, not_expired_token, never_expires_token])
      end
    end

    describe '.expiring_and_not_notified' do
      let_it_be(:expired_token) { create(:personal_access_token, expires_at: 2.days.ago) }
      let_it_be(:revoked_token) { create(:personal_access_token, revoked: true) }
      let_it_be(:valid_token_and_notified) { create(:personal_access_token, expires_at: 2.days.from_now, expire_notification_delivered: true) }
      let_it_be(:valid_token) { create(:personal_access_token, expires_at: 2.days.from_now) }
      let_it_be(:long_expiry_token) { create(:personal_access_token, expires_at: '999999-12-31'.to_date) }

      context 'in one day' do
        it "doesn't have any tokens" do
          expect(described_class.expiring_and_not_notified(1.day.from_now)).to be_empty
        end
      end

      context 'in three days' do
        it 'only includes a valid token' do
          expect(described_class.expiring_and_not_notified(3.days.from_now)).to contain_exactly(valid_token)
        end
      end
    end

    describe '.expired_today_and_not_notified' do
      let_it_be(:active) { create(:personal_access_token) }
      let_it_be(:expired_yesterday) { create(:personal_access_token, expires_at: Date.yesterday) }
      let_it_be(:revoked_token) { create(:personal_access_token, expires_at: Date.current, revoked: true) }
      let_it_be(:expired_today) { create(:personal_access_token, expires_at: Date.current) }
      let_it_be(:expired_today_and_notified) { create(:personal_access_token, expires_at: Date.current, after_expiry_notification_delivered: true) }

      it 'returns tokens that have expired today' do
        expect(described_class.expired_today_and_not_notified).to contain_exactly(expired_today)
      end
    end

    describe '.without_impersonation' do
      let_it_be(:impersonation_token) { create(:personal_access_token, :impersonation) }
      let_it_be(:personal_access_token) { create(:personal_access_token) }

      it 'returns only non-impersonation tokens' do
        expect(described_class.without_impersonation).to contain_exactly(personal_access_token)
      end
    end

    describe 'revoke scopes' do
      let_it_be(:revoked_token) { create(:personal_access_token, :revoked) }
      let_it_be(:non_revoked_token) { create(:personal_access_token, revoked: false) }
      let_it_be(:non_revoked_token2) { create(:personal_access_token, revoked: nil) }

      describe '.revoked' do
        it { expect(described_class.revoked).to contain_exactly(revoked_token) }
      end

      describe '.not_revoked' do
        it { expect(described_class.not_revoked).to contain_exactly(non_revoked_token, non_revoked_token2) }
      end
    end
  end

  describe '.simple_sorts' do
    it 'includes overridden keys' do
      expect(described_class.simple_sorts.keys).to include(*%w(expires_at_asc_id_desc))
    end
  end

  describe 'ordering by expires_at' do
    let_it_be(:earlier_token) { create(:personal_access_token, expires_at: 2.days.ago) }
    let_it_be(:later_token) { create(:personal_access_token, expires_at: 1.day.ago) }

    describe '.order_expires_at_asc_id_desc' do
      let_it_be(:earlier_token_2) { create(:personal_access_token, expires_at: 2.days.ago) }

      it 'returns ordered list in combination of expires_at ascending and id descending' do
        expect(described_class.order_expires_at_asc_id_desc).to eq [earlier_token_2, earlier_token, later_token]
      end
    end
  end

  # During the implementation of Admin Mode for API, tokens of
  # administrators should automatically get the `admin_mode` scope as well
  # See https://gitlab.com/gitlab-org/gitlab/-/issues/42692
  describe '`admin_mode scope' do
    subject { create(:personal_access_token, user: user, scopes: ['api']) }

    context 'with feature flag enabled' do
      context 'with administrator user' do
        let_it_be(:user) { create(:user, :admin) }

        it 'does not add `admin_mode` scope before created' do
          expect(subject.scopes).to contain_exactly('api')
        end
      end

      context 'with normal user' do
        let_it_be(:user) { create(:user) }

        it 'does not add `admin_mode` scope before created' do
          expect(subject.scopes).to contain_exactly('api')
        end
      end
    end

    context 'with feature flag disabled' do
      before do
        stub_feature_flags(admin_mode_for_api: false)
      end

      context 'with administrator user' do
        let_it_be(:user) { create(:user, :admin) }

        it 'adds `admin_mode` scope before created' do
          expect(subject.scopes).to contain_exactly('api', 'admin_mode')
        end
      end

      context 'with normal user' do
        let_it_be(:user) { create(:user) }

        it 'does not add `admin_mode` scope before created' do
          expect(subject.scopes).to contain_exactly('api')
        end
      end
    end
  end
end
