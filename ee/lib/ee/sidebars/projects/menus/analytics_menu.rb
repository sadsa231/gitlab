# frozen_string_literal: true

module EE
  module Sidebars
    module Projects
      module Menus
        module AnalyticsMenu
          extend ::Gitlab::Utils::Override
          include ::Gitlab::Utils::StrongMemoize

          override :configure_menu_items
          def configure_menu_items
            return false unless can?(context.current_user, :read_analytics, context.project)

            add_item(dashboards_analytics_menu_item)
            add_item(cycle_analytics_menu_item)
            add_item(ci_cd_analytics_menu_item)
            add_item(code_review_analytics_menu_item)
            add_item(insights_menu_item)
            add_item(issues_analytics_menu_item)
            add_item(merge_request_analytics_menu_item)
            add_item(repository_analytics_menu_item)

            true
          end

          private

          def insights_menu_item
            unless context.project.insights_available?
              return ::Sidebars::NilMenuItem.new(item_id: :insights)
            end

            ::Sidebars::MenuItem.new(
              title: _('Insights'),
              link: project_insights_path(context.project),
              active_routes: { path: 'insights#show' },
              container_html_options: { class: 'shortcuts-project-insights' },
              item_id: :insights
            )
          end

          def code_review_analytics_menu_item
            unless can?(context.current_user, :read_code_review_analytics, context.project)
              return ::Sidebars::NilMenuItem.new(item_id: :code_review)
            end

            ::Sidebars::MenuItem.new(
              title: _('Code review'),
              link: project_analytics_code_reviews_path(context.project),
              active_routes: { path: 'projects/analytics/code_reviews#index' },
              item_id: :code_review
            )
          end

          def issues_analytics_menu_item
            unless show_issues_analytics?
              return ::Sidebars::NilMenuItem.new(item_id: :issues)
            end

            ::Sidebars::MenuItem.new(
              title: _('Issue'),
              link: project_analytics_issues_analytics_path(context.project),
              active_routes: { path: 'issues_analytics#show' },
              item_id: :issues
            )
          end

          def show_issues_analytics?
            context.project.licensed_feature_available?(:issues_analytics) &&
              can?(context.current_user, :read_issue_analytics, context.project)
          end

          def merge_request_analytics_menu_item
            unless can?(context.current_user, :read_project_merge_request_analytics, context.project)
              return ::Sidebars::NilMenuItem.new(item_id: :merge_requests)
            end

            ::Sidebars::MenuItem.new(
              title: _('Merge request'),
              link: project_analytics_merge_request_analytics_path(context.project),
              active_routes: { path: 'projects/analytics/merge_request_analytics#show' },
              item_id: :merge_requests
            )
          end

          def dashboards_analytics_menu_item
            unless ::Feature.enabled?(:combined_analytics_dashboards, context.project) &&
                context.project.licensed_feature_available?(:product_analytics) &&
                can?(context.current_user, :read_product_analytics, context.project)
              return ::Sidebars::NilMenuItem.new(item_id: :dashboards_analytics)
            end

            ::Sidebars::MenuItem.new(
              title: _('Dashboards'),
              link: project_product_analytics_dashboards_path(context.project),
              container_html_options: { class: 'shortcuts-project-dashboards-analytics' },
              active_routes: { controller: :product_analytics },
              item_id: :dashboards_analytics
            )
          end
          strong_memoize_attr :dashboards_analytics_menu_item
        end
      end
    end
  end
end
