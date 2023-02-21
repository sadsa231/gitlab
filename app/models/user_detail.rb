# frozen_string_literal: true

class UserDetail < ApplicationRecord
  extend ::Gitlab::Utils::Override

  REGISTRATION_OBJECTIVE_PAIRS = { basics: 0, move_repository: 1, code_storage: 2, exploring: 3, ci: 4, other: 5, joining_team: 6 }.freeze

  belongs_to :user

  validates :pronouns, length: { maximum: 50 }
  validates :pronunciation, length: { maximum: 255 }
  validates :job_title, length: { maximum: 200 }
  validates :bio, length: { maximum: 255 }, allow_blank: true

  DEFAULT_FIELD_LENGTH = 500

  validates :linkedin, length: { maximum: DEFAULT_FIELD_LENGTH }, allow_blank: true
  validates :twitter, length: { maximum: DEFAULT_FIELD_LENGTH }, allow_blank: true
  validates :skype, length: { maximum: DEFAULT_FIELD_LENGTH }, allow_blank: true
  validates :location, length: { maximum: DEFAULT_FIELD_LENGTH }, allow_blank: true
  validates :organization, length: { maximum: DEFAULT_FIELD_LENGTH }, allow_blank: true
  validates :website_url, length: { maximum: DEFAULT_FIELD_LENGTH }, url: true, allow_blank: true, if: :website_url_changed?

  before_validation :sanitize_attrs
  before_save :prevent_nil_fields

  enum registration_objective: REGISTRATION_OBJECTIVE_PAIRS, _suffix: true

  def sanitize_attrs
    %i[linkedin skype twitter website_url].each do |attr|
      value = self[attr]
      self[attr] = Sanitize.clean(value) if value.present?
    end
    %i[location organization].each do |attr|
      value = self[attr]
      self[attr] = Sanitize.clean(value).gsub('&amp;', '&') if value.present?
    end
  end

  private

  def prevent_nil_fields
    self.bio = '' if bio.nil?
    self.linkedin = '' if linkedin.nil?
    self.twitter = '' if twitter.nil?
    self.skype = '' if skype.nil?
    self.location = '' if location.nil?
    self.organization = '' if organization.nil?
    self.website_url = '' if website_url.nil?
  end
end

UserDetail.prepend_mod_with('UserDetail')
