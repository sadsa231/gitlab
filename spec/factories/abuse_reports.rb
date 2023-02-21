# frozen_string_literal: true

FactoryBot.define do
  factory :abuse_report do
    reporter factory: :user
    user
    message { 'User sends spam' }
    reported_from_url { 'http://gitlab.com' }
    links_to_spam { ['https://gitlab.com/issue1', 'https://gitlab.com/issue2'] }
  end
end
