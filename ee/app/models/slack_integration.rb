# frozen_string_literal: true

class SlackIntegration < ApplicationRecord
  include EachBatch

  ALL_FEATURES = %i[commands notifications].freeze

  SCOPE_COMMANDS = 'commands'
  SCOPE_CHAT_WRITE = 'chat:write'
  SCOPE_CHAT_WRITE_PUBLIC = 'chat:write.public'

  # These scopes are requested when installing the app, additional scopes
  # will need reauthorization.
  # https://api.slack.com/authentication/oauth-v2#asking
  SCOPES = [SCOPE_COMMANDS, SCOPE_CHAT_WRITE, SCOPE_CHAT_WRITE_PUBLIC].freeze

  belongs_to :integration

  attr_encrypted :bot_access_token,
    mode: :per_attribute_iv,
    key: Settings.attr_encrypted_db_key_base_32,
    algorithm: 'aes-256-gcm',
    encode: false,
    encode_iv: false

  has_many :slack_integrations_scopes,
    class_name: '::Integrations::SlackWorkspace::IntegrationApiScope'

  has_many :slack_api_scopes,
    class_name: '::Integrations::SlackWorkspace::ApiScope',
    through: :slack_integrations_scopes

  scope :with_bot, -> { where.not(bot_user_id: nil) }
  scope :by_team, -> (team_id) { where(team_id: team_id) }

  validates :team_id, presence: true
  validates :team_name, presence: true
  validates :alias, presence: true,
                    uniqueness: { scope: :team_id, message: 'This alias has already been taken' },
                    length: 2..4096
  validates :user_id, presence: true
  validates :integration, presence: true

  after_commit :update_active_status_of_integration, on: [:create, :destroy]

  def update_active_status_of_integration
    integration.update_active_status
  end

  def feature_available?(feature_name)
    case feature_name
    when :commands
      # The slash commands feature requires 'commands' scope.
      # All records will support this scope, as this was the original feature.
      true
    when :notifications
      scoped_to?(SCOPE_CHAT_WRITE, SCOPE_CHAT_WRITE_PUBLIC)
    else
      false
    end
  end

  def upgrade_needed?
    !all_features_supported?
  end

  def all_features_supported?
    ALL_FEATURES.all? { feature_available?(_1) } # rubocop: disable Gitlab/FeatureAvailableUsage
  end

  def authorized_scope_names=(names)
    names = Array.wrap(names).flat_map { _1.split(',') }.map(&:strip)

    scopes = ::Integrations::SlackWorkspace::ApiScope.find_or_initialize_by_names(names)
    self.slack_api_scopes = scopes
  end

  def authorized_scope_names
    slack_api_scopes.pluck(:name)
  end

  private

  def scoped_to?(*names)
    return false if names.empty?

    names.to_set <= all_scopes
  end

  def all_scopes
    @all_scopes = authorized_scope_names.to_set
  end
end
