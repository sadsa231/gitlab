# frozen_string_literal: true

module Sidebars
  module YourWork
    class Panel < ::Sidebars::Panel
      override :configure_menus
      def configure_menus
        add_menus
      end

      override :aria_label
      def aria_label
        _('Your work')
      end

      override :render_raw_scope_menu_partial
      def render_raw_scope_menu_partial
        "shared/nav/your_work_scope_header"
      end

      private

      def add_menus
        add_menu(Sidebars::YourWork::Menus::ProjectsMenu.new(context))
        add_menu(Sidebars::YourWork::Menus::GroupsMenu.new(context))
        add_menu(Sidebars::YourWork::Menus::IssuesMenu.new(context))
        add_menu(Sidebars::YourWork::Menus::MergeRequestsMenu.new(context))
        add_menu(Sidebars::YourWork::Menus::TodosMenu.new(context))
        add_menu(Sidebars::YourWork::Menus::MilestonesMenu.new(context))
        add_menu(Sidebars::YourWork::Menus::SnippetsMenu.new(context))
        add_menu(Sidebars::YourWork::Menus::ActivityMenu.new(context))
      end
    end
  end
end
