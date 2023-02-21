# frozen_string_literal: true

require 'gitlab'
require_relative 'default_options'

class CreateIssue
  def initialize(options)
    @project = options.fetch(:project)

    # Force the token to be a string so that if api_token is nil, it's set to '',
    # allowing unauthenticated requests (for forks).
    api_token = options.delete(:api_token).to_s

    warn "No API token given." if api_token.empty?

    @client = Gitlab.client(
      endpoint: options.delete(:endpoint) || API::DEFAULT_OPTIONS[:endpoint],
      private_token: api_token
    )
  end

  def execute(issue_data)
    client.create_issue(project, issue_data.delete(:title), issue_data)
  end

  private

  attr_reader :project, :client
end
