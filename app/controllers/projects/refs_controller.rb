# frozen_string_literal: true

class Projects::RefsController < Projects::ApplicationController
  include ExtractsPath
  include TreeHelper

  around_action :allow_gitaly_ref_name_caching, only: [:logs_tree]

  before_action :require_non_empty_project
  before_action :validate_ref_id
  before_action :assign_ref_vars
  before_action :authorize_read_code!

  feature_category :source_code_management
  urgency :low, [:switch, :logs_tree]

  def switch
    respond_to do |format|
      format.html do
        new_path =
          case permitted_params[:destination]
          when "tree"
            project_tree_path(@project, @id)
          when "blob"
            project_blob_path(@project, @id)
          when "graph"
            if Feature.enabled?(:use_ref_type_parameter, @project)
              project_network_path(@project, @id, ref_type: ref_type)
            else
              project_network_path(@project, @id, @options)
            end
          when "graphs"
            if Feature.enabled?(:use_ref_type_parameter, @project)
              project_graph_path(@project, @id, ref_type: ref_type)
            else
              project_graph_path(@project, @id)
            end
          when "find_file"
            project_find_file_path(@project, @id)
          when "graphs_commits"
            commits_project_graph_path(@project, @id)
          when "badges"
            project_settings_ci_cd_path(@project, ref: @id)
          else
            if Feature.enabled?(:use_ref_type_parameter, @project)
              project_commits_path(@project, @id, ref_type: ref_type)
            else
              project_commits_path(@project, @id)
            end
          end

        redirect_to new_path
      end
    end
  end

  def logs_tree
    respond_to do |format|
      format.json do
        logs, next_offset = tree_summary.fetch_logs

        response.headers["More-Logs-Offset"] = next_offset.to_s if next_offset

        render json: logs
      end
    end
  end

  private

  def tree_summary
    ::Gitlab::TreeSummary.new(
      @commit, @project, current_user,
      path: @path, offset: permitted_params[:offset], limit: 25
    )
  end

  def validate_ref_id
    return not_found if permitted_params[:id].present? && permitted_params[:id] !~ Gitlab::PathRegex.git_reference_regex
  end

  def permitted_params
    params.permit(:id, :offset, :destination)
  end
end
