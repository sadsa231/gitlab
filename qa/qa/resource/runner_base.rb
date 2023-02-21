# frozen_string_literal: true

module QA
  module Resource
    class RunnerBase < Base
      attr_accessor :run_untagged,
        :image,
        :executor,
        :executor_image,
        :tags,
        :config

      attributes :id,
        :active,
        :paused,
        :runner_type,
        :online,
        :status,
        :ip_address,
        :description,
        :name,
        :is_shared,
        :contacted_at,
        :platform,
        :architecture,
        :projects,
        :revision,
        :tag_list,
        :version,
        :access_level,
        :maximum_timeout

      def initialize
        @tags = nil
        @config = nil
        @run_untagged = nil
        @name = "qa-runner-#{SecureRandom.hex(4)}"
        @image = 'registry.gitlab.com/gitlab-org/gitlab-runner:alpine'
        @executor = :shell
        @executor_image = 'registry.gitlab.com/gitlab-org/gitlab-build-images:gitlab-qa-alpine-ruby-2.7'
      end

      # Initially we only support fabricate via API
      def fabricate!
        fabricate_via_api!
      end

      # Start container and register runner
      # Fetch via API and populate attributes
      #
      def fabricate_via_api!
        api_get
      rescue NoValueError
        # Start container on initial fabrication and populate all attributes once id is known
        # see: https://docs.gitlab.com/ee/api/runners.html#get-runners-details
        start_container_and_register
        api_get
      end

      def remove_via_api!
        super
      ensure
        @docker_container.remove!
        @docker_container = nil
      end

      def api_get_path
        "/runners/#{id}"
      end

      def api_post_path
        "/runners"
      end

      def api_delete_path
        api_get_path
      end

      def api_post_body; end

      def wait_until_online
        Runtime::Logger.info('Waiting for runner to come online...')
        Support::Retrier.retry_until(max_duration: 60, sleep_interval: 1) do
          reload! && status == 'online'
        end
      end

      def restart
        Runtime::Logger.info("Restarting runner container #{name}...")
        @docker_container.restart
        wait_until_online
      end

      private

      def start_container_and_register
        @docker_container ||= Service::DockerRun::GitlabRunner.new(name).tap do |runner|
          Support::Retrier.retry_on_exception(sleep_interval: 5) do
            runner.pull
          end

          runner.token = token
          runner.address = Runtime::Scenario.gitlab_address
          runner.tags = tags if tags
          runner.image = image
          runner.config = config if config
          runner.executor = executor
          runner.executor_image = executor_image if executor == :docker
          runner.run_untagged = run_untagged if run_untagged
          runner.register!
        end
        populate_initial_id
      rescue StandardError => e
        @docker_container&.remove!
        raise(e)
      end

      def populate_initial_id
        tag_list = tags ? { tag_list: tags.compact.join(',') } : {}
        runner = runner(**tag_list)
        @id = runner[:id]
      end

      def runner(**kwargs)
        raise NotImplementedError
      end
    end
  end
end
