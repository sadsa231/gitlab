# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Diff::FileCollection::MergeRequestDiffBase do
  let(:merge_request) { create(:merge_request) }
  let(:diffable) { merge_request.merge_request_diff }

  describe '#overflow?' do
    subject(:overflown) { described_class.new(diffable, diff_options: nil).overflow? }

    context 'when it is not overflown' do
      it 'returns false' do
        expect(overflown).to eq(false)
      end
    end

    context 'when it is overflown' do
      before do
        diffable.update!(state: :overflow)
      end

      it 'returns true' do
        expect(overflown).to eq(true)
      end
    end
  end

  describe '#diff_files' do
    subject(:diff_files) { described_class.new(diffable, diff_options: nil).diff_files }

    it 'measures diffs_highlight_cache_decorate' do
      allow(Gitlab::Metrics).to receive(:measure).and_call_original
      expect(Gitlab::Metrics).to receive(:measure).with(:diffs_highlight_cache_decorate).and_call_original

      diff_files
    end
  end

  describe '#cache_key' do
    subject(:cache_key) { described_class.new(diffable, diff_options: nil).cache_key }

    it 'returns cache_key from merge_request_diff' do
      expect(cache_key).to eq diffable.cache_key
    end
  end
end
