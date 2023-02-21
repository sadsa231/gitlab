# frozen_string_literal: true

require 'fileutils'

module Tasks
  module Gitlab
    module Assets
      FOSS_ASSET_FOLDERS = %w[app/assets fixtures/emojis vendor/assets].freeze
      EE_ASSET_FOLDERS = %w[ee/app/assets].freeze
      JH_ASSET_FOLDERS = %w[jh/app/assets].freeze
      # In the new caching strategy, we check the assets hash sum *before* compiling
      # the app/assets/javascripts/locale/**/app.js files. That means the hash sum
      # must depend on locale/**/gitlab.po.
      JS_ASSET_PATTERNS = %w[*.js config/**/*.js locale/**/gitlab.po].freeze
      JS_ASSET_FILES = %w[
        package.json
        yarn.lock
        babel.config.js
        config/webpack.config.js
      ].freeze
      EXCLUDE_PATTERNS = %w[
        app/assets/javascripts/locale/**/app.js
      ].freeze
      PUBLIC_ASSETS_DIR = 'public/assets'
      HEAD_ASSETS_SHA256_HASH_ENV = 'GITLAB_ASSETS_HASH'
      CACHED_ASSETS_SHA256_HASH_FILE = 'cached-assets-hash.txt'

      def self.master_assets_sha256
        @master_assets_sha256 ||=
          if File.exist?(Tasks::Gitlab::Assets::CACHED_ASSETS_SHA256_HASH_FILE)
            File.read(Tasks::Gitlab::Assets::CACHED_ASSETS_SHA256_HASH_FILE)
          else
            'missing!'
          end
      end

      def self.head_assets_sha256
        @head_assets_sha256 ||= ENV.fetch(Tasks::Gitlab::Assets::HEAD_ASSETS_SHA256_HASH_ENV) do
          Tasks::Gitlab::Assets.sha256_of_assets_impacting_compilation(verbose: false)
        end
      end

      def self.sha256_of_assets_impacting_compilation(verbose: true)
        start_time = Time.now
        asset_files = assets_impacting_compilation
        puts "Generating the SHA256 hash for #{asset_files.size} Webpack-related assets..." if verbose

        assets_sha256 = asset_files.map { |asset_file| Digest::SHA256.file(asset_file).hexdigest }.join

        Digest::SHA256.hexdigest(assets_sha256).tap { |sha256| puts "=> SHA256 generated in #{Time.now - start_time}: #{sha256}" if verbose }
      end

      def self.assets_impacting_compilation
        assets_folders = FOSS_ASSET_FOLDERS
        assets_folders += EE_ASSET_FOLDERS if ::Gitlab.ee?
        assets_folders += JH_ASSET_FOLDERS if ::Gitlab.jh?

        asset_files = Dir.glob(JS_ASSET_PATTERNS)
        asset_files += JS_ASSET_FILES

        assets_folders.each do |folder|
          asset_files.concat(Dir.glob(["#{folder}/**/*.*"]))
        end

        asset_files - Dir.glob(EXCLUDE_PATTERNS)
      end
      private_class_method :assets_impacting_compilation
    end
  end
end

namespace :gitlab do
  namespace :assets do
    desc 'GitLab | Assets | Return the hash sum of all frontend assets'
    task :hash_sum do
      print Tasks::Gitlab::Assets.sha256_of_assets_impacting_compilation(verbose: false)
    end

    desc 'GitLab | Assets | Compile all frontend assets'
    task :compile do
      require_dependency 'gitlab/task_helpers'

      puts "Assets SHA256 for `master`: #{Tasks::Gitlab::Assets.master_assets_sha256.inspect}"
      puts "Assets SHA256 for `HEAD`: #{Tasks::Gitlab::Assets.head_assets_sha256.inspect}"

      if Tasks::Gitlab::Assets.head_assets_sha256 != Tasks::Gitlab::Assets.master_assets_sha256
        FileUtils.rm_rf([Tasks::Gitlab::Assets::PUBLIC_ASSETS_DIR] + Dir.glob('app/assets/javascripts/locale/**/app.js'))

        # gettext:po_to_json needs to run before rake:assets:precompile because
        # app/assets/javascripts/locale/**/app.js are pre-compiled by Sprockets
        Gitlab::TaskHelpers.invoke_and_time_task('gettext:po_to_json')
        Gitlab::TaskHelpers.invoke_and_time_task('rake:assets:precompile')

        log_path = ENV['WEBPACK_COMPILE_LOG_PATH']

        cmd = 'yarn webpack'
        cmd += " > #{log_path}" if log_path

        unless system(cmd)
          abort 'Error: Unable to compile webpack production bundle.'.color(:red)
        end

        puts "Written webpack stdout log to #{log_path}" if log_path
        puts "You can inspect the webpack log here: #{ENV['CI_JOB_URL']}/artifacts/file/#{log_path}" if log_path && ENV['CI_JOB_URL']

        Gitlab::TaskHelpers.invoke_and_time_task('gitlab:assets:fix_urls')
        Gitlab::TaskHelpers.invoke_and_time_task('gitlab:assets:check_page_bundle_mixins_css_for_sideeffects')
      end
    end

    desc 'GitLab | Assets | Clean up old compiled frontend assets'
    task clean: ['rake:assets:clean']

    desc 'GitLab | Assets | Remove all compiled frontend assets'
    task purge: ['rake:assets:clobber']

    desc 'GitLab | Assets | Uninstall frontend dependencies'
    task purge_modules: ['yarn:clobber']

    desc 'GitLab | Assets | Fix all absolute url references in CSS'
    task :fix_urls do
      css_files = Dir['public/assets/*.css']
      css_files.each do |file|
        # replace url(/assets/*) with url(./*)
        puts "Fixing #{file}"
        system "sed", "-i", "-e", 's/url(\([\"\']\?\)\/assets\//url(\1.\//g', file

        # rewrite the corresponding gzip file (if it exists)
        gzip = "#{file}.gz"
        next unless File.exist?(gzip)

        puts "Fixing #{gzip}"

        FileUtils.rm(gzip)
        mtime = File.stat(file).mtime

        File.open(gzip, 'wb+') do |f|
          gz = Zlib::GzipWriter.new(f, Zlib::BEST_COMPRESSION)
          gz.mtime = mtime
          gz.write File.binread(file)
          gz.close

          File.utime(mtime, mtime, f.path)
        end
      end
    end

    desc 'GitLab | Assets | Compile vendor assets'
    task :vendor do
      unless system('yarn webpack-vendor')
        abort 'Error: Unable to compile webpack DLL.'.color(:red)
      end
    end

    desc 'GitLab | Assets | Check that scss mixins do not introduce any sideffects'
    task :check_page_bundle_mixins_css_for_sideeffects do
      unless system('./scripts/frontend/check_page_bundle_mixins_css_for_sideeffects.js')
        abort 'Error: At least one CSS changes introduces an unwanted sideeffect'.color(:red)
      end
    end
  end
end
