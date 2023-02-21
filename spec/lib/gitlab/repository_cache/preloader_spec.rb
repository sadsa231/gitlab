# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::RepositoryCache::Preloader, :use_clean_rails_redis_caching,
                                                   feature_category: :source_code_management do
  let(:projects) { create_list(:project, 2, :repository) }
  let(:repositories) { projects.map(&:repository) }

  before do
    stub_feature_flags(use_primary_store_as_default_for_repository_cache: false)
  end

  shared_examples 'preload' do
    describe '#preload' do
      context 'when the values are already cached' do
        before do
          # Warm the cache but use a different model so they are not memoized
          repos = Project.id_in(projects).order(:id).map(&:repository)

          allow(repos[0].head_tree).to receive(:readme_path).and_return('README.txt')
          allow(repos[1].head_tree).to receive(:readme_path).and_return('README.md')

          repos.map(&:exists?)
          repos.map(&:readme_path)
        end

        it 'prevents individual cache reads for cached methods' do
          expect(cache).to receive(:read_multi).once.and_call_original

          described_class.new(repositories).preload(
            %i[exists? readme_path]
          )

          expect(cache).not_to receive(:read)
          expect(cache).not_to receive(:write)

          expect(repositories[0].exists?).to eq(true)
          expect(repositories[0].readme_path).to eq('README.txt')

          expect(repositories[1].exists?).to eq(true)
          expect(repositories[1].readme_path).to eq('README.md')
        end
      end

      context 'when values are not cached' do
        it 'reads and writes from cache individually' do
          described_class.new(repositories).preload(
            %i[exists? has_visible_content?]
          )

          expect(cache).to receive(:read).exactly(4).times
          expect(cache).to receive(:write).exactly(4).times

          repositories.each(&:exists?)
          repositories.each(&:has_visible_content?)
        end
      end
    end
  end

  context 'when use_primary_and_secondary_stores_for_repository_cache feature flag is enabled' do
    let(:cache) { Gitlab::RepositoryCache.store }

    before do
      stub_feature_flags(use_primary_and_secondary_stores_for_repository_cache: true)
    end

    it_behaves_like 'preload'
  end

  context 'when use_primary_and_secondary_stores_for_repository_cache feature flag is disabled' do
    let(:cache) { Rails.cache }

    before do
      stub_feature_flags(use_primary_and_secondary_stores_for_repository_cache: false)
    end

    it_behaves_like 'preload'
  end
end
