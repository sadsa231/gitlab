# frozen_string_literal: true

module Sidebars
  module Projects
    module Menus
      class RepositoryMenu < ::Sidebars::Menu
        override :configure_menu_items
        def configure_menu_items
          return false unless can?(context.current_user, :read_code, context.project)
          return false if context.project.empty_repo?

          add_item(files_menu_item)
          add_item(commits_menu_item)
          add_item(branches_menu_item)
          add_item(tags_menu_item)
          add_item(contributors_menu_item)
          add_item(graphs_menu_item)
          add_item(compare_menu_item)

          true
        end

        override :extra_container_html_options
        def extra_container_html_options
          {
            class: 'shortcuts-tree'
          }
        end

        override :title
        def title
          _('Repository')
        end

        override :title_html_options
        def title_html_options
          {
            id: 'js-onboarding-repo-link'
          }
        end

        override :sprite_icon
        def sprite_icon
          'doc-text'
        end

        private

        def files_menu_item
          ::Sidebars::MenuItem.new(
            title: _('Files'),
            link: project_tree_path(context.project, context.current_ref),
            active_routes: { controller: %w[tree blob blame edit_tree new_tree find_file] },
            item_id: :files
          )
        end

        def commits_menu_item
          link = if Feature.enabled?(:use_ref_type_parameter, context.project)
                   project_commits_path(context.project, context.current_ref, ref_type: ref_type_from_context(context))
                 else
                   project_commits_path(context.project, context.current_ref)
                 end

          ::Sidebars::MenuItem.new(
            title: _('Commits'),
            link: link,
            active_routes: { controller: %w(commit commits) },
            item_id: :commits,
            container_html_options: { id: 'js-onboarding-commits-link' }
          )
        end

        def branches_menu_item
          ::Sidebars::MenuItem.new(
            title: _('Branches'),
            link: project_branches_path(context.project),
            active_routes: { controller: :branches },
            item_id: :branches,
            container_html_options: { id: 'js-onboarding-branches-link' }
          )
        end

        def tags_menu_item
          ::Sidebars::MenuItem.new(
            title: _('Tags'),
            link: project_tags_path(context.project),
            item_id: :tags,
            active_routes: { controller: :tags }
          )
        end

        def contributors_menu_item
          return false unless context.project.analytics_enabled?

          link = if Feature.enabled?(:use_ref_type_parameter, context.project)
                   project_graph_path(context.project, context.current_ref, ref_type: ref_type_from_context(context))
                 else
                   project_graph_path(context.project, context.current_ref)
                 end

          ::Sidebars::MenuItem.new(
            title: _('Contributors'),
            link: link,
            active_routes: { path: 'graphs#show' },
            item_id: :contributors
          )
        end

        def graphs_menu_item
          link = if Feature.enabled?(:use_ref_type_parameter, context.project)
                   project_network_path(context.project, context.current_ref, ref_type: ref_type_from_context(context))
                 else
                   project_network_path(context.project, context.current_ref)
                 end

          ::Sidebars::MenuItem.new(
            title: _('Graph'),
            link: link,
            active_routes: { controller: :network },
            item_id: :graphs
          )
        end

        def compare_menu_item
          ::Sidebars::MenuItem.new(
            title: _('Compare'),
            link: project_compare_index_path(context.project, from: context.project.repository.root_ref, to: context.current_ref),
            active_routes: { controller: :compare },
            item_id: :compare
          )
        end

        def ref_type_from_context(context)
          ref_type = context.try(:ref_type)
          ref_type ||= 'heads' if context.current_ref == context.project.repository.root_ref
          ref_type
        end
      end
    end
  end
end

Sidebars::Projects::Menus::RepositoryMenu.prepend_mod_with('Sidebars::Projects::Menus::RepositoryMenu')
