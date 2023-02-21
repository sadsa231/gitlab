# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::ContainerRepositoryReplicator, :geo, feature_category: :geo_replication do
  let(:model_record) { create(:container_repository) }

  subject(:replicator) { model_record.replicator }

  # Based on shared example 'a repository replicator'
  context 'for base replicator functionality' do
    include EE::GeoHelpers

    let_it_be(:primary) { create(:geo_node, :primary) }
    let_it_be(:secondary) { create(:geo_node) }

    before do
      stub_current_geo_node(primary)
    end

    it_behaves_like 'a replicator'

    # This could be included in each model's spec, but including it here is DRYer.
    include_examples 'a replicable model' do
      let(:replicator_class) { described_class }
    end

    describe '#handle_after_update' do
      it 'creates a Geo::Event' do
        expect do
          replicator.handle_after_update
        end.to change(::Geo::Event, :count).by(1)

        expect(::Geo::Event.last.attributes).to include(
          "replicable_name" => replicator.replicable_name,
          "event_name" => "updated",
          "payload" => { "model_record_id" => replicator.model_record.id })
      end

      context 'when replication feature flag is disabled' do
        before do
          stub_feature_flags(replicator.replication_enabled_feature_key => false)
        end

        it 'does not publish' do
          expect(replicator).not_to receive(:publish)

          replicator.handle_after_update
        end
      end
    end

    describe '#handle_after_destroy' do
      it 'creates a Geo::Event' do
        expect do
          replicator.handle_after_destroy
        end.to change(::Geo::Event, :count).by(1)

        expect(::Geo::Event.last.attributes).to include(
          "replicable_name" => replicator.replicable_name,
          "event_name" => "deleted",
          "payload" => {
            "model_record_id" => replicator.model_record.id,
            "path" => replicator.model_record.path
          })
      end

      context 'when replication feature flag is disabled' do
        before do
          stub_feature_flags(replicator.replication_enabled_feature_key => false)
        end

        it 'does not publish' do
          expect(replicator).not_to receive(:publish)

          replicator.handle_after_destroy
        end
      end
    end

    describe 'updated event consumption' do
      before do
        model_record.save!
      end

      context 'when in replicables_for_current_secondary list' do
        it 'runs Geo::ContainerRepositorySyncService service' do
          allow(replicator).to receive(:in_replicables_for_current_secondary?).and_return(true)
          sync_service = double

          expect(sync_service).to receive(:execute)
          expect(::Geo::ContainerRepositorySyncService)
            .to receive(:new).with(model_record)
                  .and_return(sync_service)

          replicator.consume(:updated)
        end
      end

      context 'when not in replicables_for_current_secondary list' do
        it 'does not run Geo::ContainerRepositorySyncService service' do
          allow(replicator).to receive(:in_replicables_for_current_secondary?).and_return(false)

          expect(::Geo::ContainerRepositorySyncService)
            .not_to receive(:new)

          replicator.consume(:updated)
        end
      end
    end

    describe 'created event consumption' do
      it 'calls update event consumer' do
        expect(replicator).to receive(:consume_event_updated)

        replicator.consume_event_created
      end
    end

    describe 'deleted event consumption' do
      before do
        model_record.save!
      end

      it 'runs Geo::ContainerRepositoryRegistryRemovalService service' do
        removal_service = double

        expect(removal_service).to receive(:execute)
        expect(::Geo::ContainerRepositoryRegistryRemovalService)
          .to receive(:new).with(model_record.id, model_record.path)
                .and_return(removal_service)

        replicator.consume(:deleted, model_record_id: model_record, path: model_record.path)
      end
    end

    describe '#model' do
      let(:invoke_model) { replicator.class.model }

      it 'is implemented' do
        expect do
          invoke_model
        end.not_to raise_error
      end

      it 'is a Class' do
        expect(invoke_model).to be_a(Class)
      end
    end
  end
end
