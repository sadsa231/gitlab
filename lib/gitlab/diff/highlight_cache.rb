# frozen_string_literal: true
#
module Gitlab
  module Diff
    class HighlightCache
      include Gitlab::Utils::Gzip
      include Gitlab::Utils::StrongMemoize

      EXPIRATION = 1.hour
      VERSION = 2

      delegate :diffable,     to: :@diff_collection
      delegate :diff_options, to: :@diff_collection

      def initialize(diff_collection)
        @diff_collection = diff_collection
      end

      # - Reads from cache
      # - Assigns DiffFile#highlighted_diff_lines for cached files
      #
      def decorate(diff_file)
        content = read_file(diff_file)

        return [] unless content

        # TODO: We could add some kind of flag to #initialize that would allow
        #   us to force re-caching
        #   https://gitlab.com/gitlab-org/gitlab/-/issues/263508
        #
        if content.empty? && recache_due_to_size?(diff_file)
          # If the file is missing from the cache and there's reason to believe
          #   it is uncached due to a size issue around changing the values for
          #   max patch size, manually populate the hash and then set the value.
          #
          new_cache_content = {}
          new_cache_content[diff_file.file_path] = diff_file.highlighted_diff_lines.map(&:to_hash)

          write_to_redis_hash(new_cache_content)

          set_highlighted_diff_lines(diff_file, read_file(diff_file))
        else
          set_highlighted_diff_lines(diff_file, content)
        end
      end

      # For every file that isn't already contained in the redis hash, store the
      #   result of #highlighted_diff_lines, then submit the uncached content
      #   to #write_to_redis_hash to submit a single write. This avoids excessive
      #   IO generated by N+1's (1 writing for each highlighted line or file).
      #
      def write_if_empty
        return if cacheable_files.empty?

        new_cache_content = {}

        cacheable_files.each do |diff_file|
          new_cache_content[diff_file.file_path] = diff_file.highlighted_diff_lines.map(&:to_hash)
        end

        write_to_redis_hash(new_cache_content)
      end

      def clear
        with_redis do |redis|
          redis.del(key)
        end
      end

      def key
        strong_memoize(:redis_key) do
          options = [
            diff_options,
            Feature.enabled?(:use_marker_ranges, diffable.project),
            Feature.enabled?(:diff_line_syntax_highlighting, diffable.project)
          ]
          options_for_key = OpenSSL::Digest::SHA256.hexdigest(options.join)

          ['highlighted-diff-files', diffable.cache_key, VERSION, options_for_key].join(":")
        end
      end

      private

      def set_highlighted_diff_lines(diff_file, content)
        diff_file.highlighted_diff_lines = content.map do |line|
          Gitlab::Diff::Line.safe_init_from_hash(line)
        end
      end

      def recache_due_to_size?(diff_file)
        diff_file_class = diff_file.diff.class

        current_patch_safe_limit_bytes = diff_file_class.patch_safe_limit_bytes
        default_patch_safe_limit_bytes = diff_file_class.patch_safe_limit_bytes(diff_file_class::DEFAULT_MAX_PATCH_BYTES)

        # If the diff is >= than the default limit, but less than the current
        #   limit, it is likely uncached due to having hit the default limit,
        #   making it eligible for recalculating.
        #
        diff_file.diff.diff_bytesize.between?(
          default_patch_safe_limit_bytes,
          current_patch_safe_limit_bytes
        )
      end

      def cacheable_files
        strong_memoize(:cacheable_files) do
          diff_files.select { |file| cacheable?(file) && read_file(file).nil? }
        end
      end

      # Given a hash of:
      #   { "file/to/cache" =>
      #   [ { line_code: "a5cc2925ca8258af241be7e5b0381edf30266302_19_19",
      #       rich_text: " <span id=\"LC19\" class=\"line\" lang=\"plaintext\">config/initializers/secret_token.rb</span>\n",
      #       text: " config/initializers/secret_token.rb",
      #       type: nil,
      #       index: 3,
      #       old_pos: 19,
      #       new_pos: 19 }
      #   ] }
      #
      #   ...it will write/update a Gitlab::Redis hash (HSET)
      #
      def write_to_redis_hash(hash)
        with_redis do |redis|
          redis.pipelined do |pipeline|
            hash.each do |diff_file_id, highlighted_diff_lines_hash|
              pipeline.hset(
                key,
                diff_file_id,
                gzip_compress(highlighted_diff_lines_hash.to_json)
              )
            rescue Encoding::UndefinedConversionError, EncodingError, JSON::GeneratorError
              nil
            end

            # HSETs have to have their expiration date manually updated
            pipeline.expire(key, EXPIRATION)
          end

          record_memory_usage(fetch_memory_usage(redis, key))
        end

        # Subsequent read_file calls would need the latest cache.
        #
        clear_memoization(:cached_content)
        clear_memoization(:cacheable_files)
      end

      def record_memory_usage(memory_usage)
        if memory_usage
          current_transaction&.observe(:gitlab_redis_diff_caching_memory_usage_bytes, memory_usage) do
            docstring 'Redis diff caching memory usage by key'
            buckets [100, 1_000, 10_000, 100_000, 1_000_000, 10_000_000]
          end
        end
      end

      def fetch_memory_usage(redis, key)
        # Redis versions prior to 4.0.0 do not support memory usage reporting
        #   for a specific key. As of 11-March-2020 we support Redis 3.x, so
        #   need to account for this. We can remove this check once we
        #   officially cease supporting versions <4.0.0.
        #
        return if Gem::Version.new(redis.info["redis_version"]) < Gem::Version.new("4")

        redis.memory("USAGE", key)
      end

      def file_paths
        strong_memoize(:file_paths) do
          diff_files.collect(&:file_path)
        end
      end

      def read_file(diff_file)
        cached_content[diff_file.file_path]
      end

      def cached_content
        strong_memoize(:cached_content) { read_cache }
      end

      def read_cache
        return {} unless file_paths.any?

        results = []
        cache_key = key # Moving out redis calls for feature flags out of redis.pipelined

        with_redis do |redis|
          redis.pipelined do |pipeline|
            results = pipeline.hmget(cache_key, file_paths)
            pipeline.expire(key, EXPIRATION)
          end
        end

        results = results.value

        record_hit_ratio(results)

        results.map! do |result|
          Gitlab::Json.parse(gzip_decompress(result), symbolize_names: true) unless result.nil?
        end

        file_paths.zip(results).to_h
      end

      def cacheable?(diff_file)
        diffable.present? && diff_file.text? && diff_file.diffable?
      end

      def diff_files
        # We access raw_diff_files here, as diff_files will attempt to apply the
        #   highlighting code found in this class, leading  to a circular
        #   reference.
        #
        @diff_collection.raw_diff_files
      end

      def current_transaction
        ::Gitlab::Metrics::WebTransaction.current
      end

      def with_redis(&block)
        Gitlab::Redis::Cache.with(&block) # rubocop:disable CodeReuse/ActiveRecord
      end

      def record_hit_ratio(results)
        current_transaction&.increment(:gitlab_redis_diff_caching_requests_total)
        current_transaction&.increment(:gitlab_redis_diff_caching_hits_total) if results.any?(&:present?)
      end
    end
  end
end
