# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module External
        class Mapper
          # Fetches file contents and verifies them
          class Verifier < Base
            private

            def process_without_instrumentation(files)
              if ::Feature.disabled?(:ci_batch_request_for_local_and_project_includes, context.project)
                return legacy_process_without_instrumentation(files)
              end

              files.each do |file|
                verify_execution_time!

                file.validate_location!
                file.validate_context! if file.valid?
                file.content if file.valid?
              end

              # We do not combine the loops because we need to load the content of all files before continuing
              # to call `BatchLoader` for all locations.
              files.each do |file| # rubocop:disable Style/CombinableLoops
                # Checking the max includes will be changed with https://gitlab.com/gitlab-org/gitlab/-/issues/367150
                verify_max_includes!
                verify_execution_time!

                file.validate_content! if file.valid?
                file.load_and_validate_expanded_hash! if file.valid?

                context.expandset.add(file)
              end
            end

            # Will be removed with the FF ci_batch_request_for_local_and_project_includes
            def legacy_process_without_instrumentation(files)
              files.select do |file|
                verify_max_includes!
                verify_execution_time!

                file.validate!

                context.expandset.add(file)
              end
            end

            def verify_max_includes!
              return if context.expandset.count < context.max_includes

              raise Mapper::TooManyIncludesError, "Maximum of #{context.max_includes} nested includes are allowed!"
            end

            def verify_execution_time!
              context.check_execution_time!
            end
          end
        end
      end
    end
  end
end
