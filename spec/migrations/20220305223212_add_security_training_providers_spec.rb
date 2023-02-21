# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe AddSecurityTrainingProviders, :migration, feature_category: :vulnerability_management do
  include MigrationHelpers::WorkItemTypesHelper

  let!(:security_training_providers) { table(:security_training_providers) }

  it 'creates default data' do
    # Need to delete all as security training providers are seeded before entire test suite
    security_training_providers.delete_all

    reversible_migration do |migration|
      migration.before -> {
        expect(security_training_providers.count).to eq(0)
      }

      migration.after -> {
        expect(security_training_providers.count).to eq(2)
      }
    end
  end
end
