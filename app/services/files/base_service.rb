# frozen_string_literal: true

module Files
  class BaseService < Commits::CreateService
    FileChangedError = Class.new(StandardError)

    def initialize(*args)
      super

      git_user = Gitlab::Git::User.from_gitlab(current_user) if current_user.present?

      @author_email = commit_email(git_user)
      @author_name = params[:author_name] || git_user&.name
      @commit_message = params[:commit_message]
      @last_commit_sha = params[:last_commit_sha]

      @file_path = params[:file_path]
      @previous_path = params[:previous_path]

      @file_content = params[:file_content]
      @file_content = Base64.decode64(@file_content) if params[:file_content_encoding] == 'base64'

      @execute_filemode = params[:execute_filemode]
    end

    def file_has_changed?(path, commit_id)
      return false unless commit_id

      last_commit = Gitlab::Git::Commit
        .last_for_path(@start_project.repository, @start_branch, path, literal_pathspec: true)

      return false unless last_commit

      last_commit.sha != commit_id
    end

    private

    def commit_email(git_user)
      return params[:author_email] if params[:author_email].present?
      return unless current_user

      namespace_commit_email = current_user.namespace_commit_email_for_project(@start_project)

      return namespace_commit_email.email.email if namespace_commit_email

      git_user.email
    end
  end
end
