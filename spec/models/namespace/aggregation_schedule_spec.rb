# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Namespace::AggregationSchedule, :clean_gitlab_redis_shared_state, type: :model do
  include ExclusiveLeaseHelpers

  let(:default_timeout) { described_class.default_lease_timeout }

  it { is_expected.to belong_to :namespace }

  describe "#default_lease_timeout" do
    subject(:default_lease_timeout) { default_timeout }

    it { is_expected.to eq 30.minutes.to_i }

    context 'when remove_namespace_aggregator_delay FF is disabled' do
      before do
        stub_feature_flags(remove_namespace_aggregator_delay: false)
      end

      it { is_expected.to eq 1.hour.to_i }
    end
  end

  describe '#schedule_root_storage_statistics' do
    let(:namespace) { create(:namespace) }
    let(:aggregation_schedule) { namespace.build_aggregation_schedule }
    let(:lease_key) { "namespace:namespaces_root_statistics:#{namespace.id}" }

    context "when we can't obtain the lease" do
      it 'does not schedule the workers' do
        stub_exclusive_lease_taken(lease_key, timeout: default_timeout)

        expect(Namespaces::RootStatisticsWorker)
          .not_to receive(:perform_async)

        expect(Namespaces::RootStatisticsWorker)
          .not_to receive(:perform_in)

        aggregation_schedule.save!
      end
    end

    context 'when we can obtain the lease' do
      it 'schedules a root storage statistics after create' do
        stub_exclusive_lease(lease_key, timeout: default_timeout)

        expect(Namespaces::RootStatisticsWorker)
          .to receive(:perform_async).once

        expect(Namespaces::RootStatisticsWorker)
          .to receive(:perform_in).once
          .with(default_timeout, aggregation_schedule.namespace_id)

        aggregation_schedule.save!
      end

      it 'does not release the lease' do
        stub_exclusive_lease(lease_key, timeout: default_timeout)

        aggregation_schedule.save!

        exclusive_lease = aggregation_schedule.exclusive_lease
        expect(exclusive_lease.exists?).to be_truthy
      end

      it 'only executes the workers once' do
        # Avoid automatic deletion of Namespace::AggregationSchedule
        # for testing purposes.
        expect(Namespaces::RootStatisticsWorker)
          .to receive(:perform_async).once
          .and_return(nil)

        expect(Namespaces::RootStatisticsWorker)
          .to receive(:perform_in).once
          .with(default_timeout, aggregation_schedule.namespace_id)
          .and_return(nil)

        # Scheduling workers for the first time
        aggregation_schedule.schedule_root_storage_statistics

        # Executing again, this time workers should not be scheduled
        # due to the lease not been released.
        aggregation_schedule.schedule_root_storage_statistics
      end
    end
  end
end
