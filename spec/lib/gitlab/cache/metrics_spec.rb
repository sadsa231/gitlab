# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Cache::Metrics do
  subject(:metrics) do
    described_class.new(
      caller_id: caller_id,
      cache_identifier: cache_identifier,
      feature_category: feature_category,
      backing_resource: backing_resource
    )
  end

  let(:caller_id) { 'caller-id' }
  let(:cache_identifier) { 'ApplicationController#show' }
  let(:feature_category) { :source_code_management }
  let(:backing_resource) { :unknown }

  let(:counter_mock) { instance_double(Prometheus::Client::Counter) }

  before do
    allow(Gitlab::Metrics).to receive(:counter)
      .with(
        :redis_hit_miss_operations_total,
        'Hit/miss Redis cache counter'
      ).and_return(counter_mock)
  end

  describe '#initialize' do
    context 'when backing resource is not supported' do
      let(:backing_resource) { 'foo' }

      it { expect { metrics }.to raise_error(RuntimeError) }

      context 'when on production' do
        before do
          allow(Gitlab).to receive(:dev_or_test_env?).and_return(false)
        end

        it 'does not raise an exception' do
          expect { metrics }.not_to raise_error
        end
      end
    end
  end

  describe '#increment_cache_hit' do
    subject { metrics.increment_cache_hit }

    it 'increments number of hits' do
      expect(counter_mock)
        .to receive(:increment)
        .with(
          {
            caller_id: caller_id,
            cache_identifier: cache_identifier,
            feature_category: feature_category,
            backing_resource: backing_resource,
            cache_hit: true
          }
        ).once

      subject
    end
  end

  describe '#increment_cache_miss' do
    subject { metrics.increment_cache_miss }

    it 'increments number of misses' do
      expect(counter_mock)
        .to receive(:increment)
        .with(
          {
            caller_id: caller_id,
            cache_identifier: cache_identifier,
            feature_category: feature_category,
            backing_resource: backing_resource,
            cache_hit: false
          }
        ).once

      subject
    end
  end

  describe '#observe_cache_generation' do
    subject do
      metrics.observe_cache_generation { action }
    end

    let(:action) { 'action' }
    let(:histogram_mock) { instance_double(Prometheus::Client::Histogram) }

    before do
      allow(Gitlab::Metrics::System).to receive(:monotonic_time).and_return(100.0, 500.0)
    end

    it 'updates histogram metric' do
      expect(Gitlab::Metrics).to receive(:histogram).with(
        :redis_cache_generation_duration_seconds,
        'Duration of Redis cache generation',
        {
          caller_id: caller_id,
          cache_identifier: cache_identifier,
          feature_category: feature_category,
          backing_resource: backing_resource
        },
        [0, 1, 5]
      ).and_return(histogram_mock)

      expect(histogram_mock).to receive(:observe).with({}, 400.0)

      is_expected.to eq(action)
    end
  end
end
