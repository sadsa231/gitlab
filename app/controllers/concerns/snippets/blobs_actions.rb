# frozen_string_literal: true

module Snippets::BlobsActions
  extend ActiveSupport::Concern

  include Gitlab::Utils::StrongMemoize
  include ExtractsRef
  include Snippets::SendBlob

  included do
    before_action :authorize_read_snippet!, only: [:raw]
    before_action :ensure_repository
    before_action :ensure_blob
  end

  def raw
    send_snippet_blob(snippet, blob)
  end

  private

  def repository_container
    snippet
  end

  # rubocop:disable Gitlab/ModuleWithInstanceVariables
  def blob
    assign_ref_vars

    return unless @commit

    @repo.blob_at(@commit.id, @path)
  end
  strong_memoize_attr :blob
  # rubocop:enable Gitlab/ModuleWithInstanceVariables

  def ensure_blob
    render_404 unless blob
  end

  def ensure_repository
    return if snippet.repo_exists?

    Gitlab::AppLogger.error(message: "Snippet raw blob attempt with no repo", snippet: snippet.id)

    respond_422
  end

  def snippet_id
    params[:snippet_id]
  end
end

Snippets::BlobsActions.prepend_mod
