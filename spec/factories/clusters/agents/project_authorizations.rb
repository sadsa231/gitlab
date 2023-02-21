# frozen_string_literal: true

FactoryBot.define do
  factory :agent_project_authorization, class: 'Clusters::Agents::ProjectAuthorization' do
    association :agent, factory: :cluster_agent
    project

    transient do
      environments { nil }
    end

    config do
      { default_namespace: 'production' }.tap do |c|
        c[:environments] = environments if environments
      end
    end
  end
end
