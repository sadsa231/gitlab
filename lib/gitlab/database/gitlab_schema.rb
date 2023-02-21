# frozen_string_literal: true

# This module gathers information about table to schema mapping
# to understand table affinity
#
# Each table / view needs to have assigned gitlab_schema. Names supported today:
#
# - gitlab_shared - defines a set of tables that are found on all databases (data accessed is dependent on connection)
# - gitlab_main / gitlab_ci - defines a set of tables that can only exist on a given application database
# - gitlab_geo - defines a set of tables that can only exist on the geo database
# - gitlab_internal - defines all internal tables of Rails and PostgreSQL
#
# Tables for the purpose of tests should be prefixed with `_test_my_table_name`

module Gitlab
  module Database
    module GitlabSchema
      UnknownSchemaError = Class.new(StandardError)

      DICTIONARY_PATH = 'db/docs/'

      def self.table_schemas(tables, undefined: true)
        tables.map { |table| table_schema(table, undefined: undefined) }.to_set
      end

      def self.table_schema(name, undefined: true)
        schema_name, table_name = name.split('.', 2) # Strip schema name like: `public.`

        # Most of names do not have schemas, ensure that this is table
        unless table_name
          table_name = schema_name
          schema_name = nil
        end

        # strip partition number of a form `loose_foreign_keys_deleted_records_1`
        table_name.gsub!(/_[0-9]+$/, '')

        # Tables and views that are properly mapped
        if gitlab_schema = views_and_tables_to_schema[table_name]
          return gitlab_schema
        end

        # Tables and views that are deleted, but we still need to reference them
        if gitlab_schema = deleted_views_and_tables_to_schema[table_name]
          return gitlab_schema
        end

        # All tables from `information_schema.` are marked as `internal`
        return :gitlab_internal if schema_name == 'information_schema'

        return :gitlab_main if table_name.start_with?('_test_gitlab_main_')

        return :gitlab_ci if table_name.start_with?('_test_gitlab_ci_')

        return :gitlab_geo if table_name.start_with?('_test_gitlab_geo_')

        # All tables that start with `_test_` without a following schema are shared and ignored
        return :gitlab_shared if table_name.start_with?('_test_')

        # All `pg_` tables are marked as `internal`
        return :gitlab_internal if table_name.start_with?('pg_')

        # When undefined it's best to return a unique name so that we don't incorrectly assume that 2 undefined schemas belong on the same database
        undefined ? :"undefined_#{table_name}" : nil
      end

      def self.dictionary_path_globs
        [Rails.root.join(DICTIONARY_PATH, '*.yml')]
      end

      def self.view_path_globs
        [Rails.root.join(DICTIONARY_PATH, 'views', '*.yml')]
      end

      def self.deleted_views_path_globs
        [Rails.root.join(DICTIONARY_PATH, 'deleted_views', '*.yml')]
      end

      def self.deleted_tables_path_globs
        [Rails.root.join(DICTIONARY_PATH, 'deleted_tables', '*.yml')]
      end

      def self.views_and_tables_to_schema
        @views_and_tables_to_schema ||= self.tables_to_schema.merge(self.views_to_schema)
      end

      def self.table_schema!(name)
        self.table_schema(name, undefined: false) || raise(
          UnknownSchemaError,
          "Could not find gitlab schema for table #{name}: Any new tables must be added to the database dictionary"
        )
      end

      def self.deleted_views_and_tables_to_schema
        @deleted_views_and_tables_to_schema ||= self.deleted_tables_to_schema.merge(self.deleted_views_to_schema)
      end

      def self.deleted_tables_to_schema
        @deleted_tables_to_schema ||= self.build_dictionary(self.deleted_tables_path_globs)
      end

      def self.deleted_views_to_schema
        @deleted_views_to_schema ||= self.build_dictionary(self.deleted_views_path_globs)
      end

      def self.tables_to_schema
        @tables_to_schema ||= self.build_dictionary(self.dictionary_path_globs)
      end

      def self.views_to_schema
        @views_to_schema ||= self.build_dictionary(self.view_path_globs)
      end

      def self.schema_names
        @schema_names ||= self.views_and_tables_to_schema.values.to_set
      end

      private_class_method def self.build_dictionary(path_globs)
        Dir.glob(path_globs).each_with_object({}) do |file_path, dic|
          data = YAML.load_file(file_path)

          key_name = data['table_name'] || data['view_name']

          dic[key_name] = data['gitlab_schema'].to_sym
        end
      end
    end
  end
end

Gitlab::Database::GitlabSchema.prepend_mod
