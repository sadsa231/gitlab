# frozen_string_literal: true

module Gitlab
  module Database
    class PostgresForeignKey < SharedModel
      self.primary_key = :oid

      # These values come from the possible confdeltype / confupdtype values in pg_constraint
      ACTION_TYPES = {
        restrict: 'r',
        cascade: 'c',
        nullify: 'n',
        set_default: 'd',
        no_action: 'a'
      }.freeze

      enum on_delete_action: ACTION_TYPES, _prefix: :on_delete

      enum on_update_action: ACTION_TYPES, _prefix: :on_update

      scope :by_referenced_table_identifier, ->(identifier) do
        raise ArgumentError, "Referenced table name is not fully qualified with a schema: #{identifier}" unless identifier =~ /^\w+\.\w+$/

        where(referenced_table_identifier: identifier)
      end

      scope :by_referenced_table_name, ->(name) { where(referenced_table_name: name) }

      scope :by_constrained_table_identifier, ->(identifier) do
        raise ArgumentError, "Constrained table name is not fully qualified with a schema: #{identifier}" unless identifier =~ /^\w+\.\w+$/

        where(constrained_table_identifier: identifier)
      end

      scope :by_constrained_table_name, ->(name) { where(constrained_table_name: name) }

      scope :not_inherited, -> { where(is_inherited: false) }

      scope :by_name, ->(name) { where(name: name) }

      scope :by_constrained_columns, ->(cols) { where(constrained_columns: Array.wrap(cols)) }

      scope :by_referenced_columns, ->(cols) { where(referenced_columns: Array.wrap(cols)) }

      scope :by_on_delete_action, ->(on_delete) do
        raise ArgumentError, "Invalid on_delete action #{on_delete}" unless on_delete_actions.key?(on_delete)

        where(on_delete_action: on_delete)
      end

      scope :by_on_update_action, ->(on_update) do
        raise ArgumentError, "Invalid on_update action #{on_update}" unless on_update_actions.key?(on_update)

        where(on_update_action: on_update)
      end
    end
  end
end
