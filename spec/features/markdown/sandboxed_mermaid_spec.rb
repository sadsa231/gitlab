# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Sandboxed Mermaid rendering', :js, feature_category: :team_planning do
  let_it_be(:project) { create(:project, :public, :repository) }
  let_it_be(:description) do
    <<~MERMAID
    ```mermaid
    graph TD;
      A-->B;
      A-->C;
      B-->D;
      C-->D;
    ```
    MERMAID
  end

  let_it_be(:expected) do
    %(<iframe src="/-/sandbox/mermaid" sandbox="allow-scripts allow-popups" frameborder="0" scrolling="no")
  end

  context 'in an issue' do
    let(:issue) { create(:issue, project: project, description: description) }

    it 'includes mermaid frame correctly', :with_license do
      visit project_issue_path(project, issue)

      wait_for_requests

      expect(page.html).to include(expected)
    end
  end

  context 'in a merge request' do
    let(:merge_request) { create(:merge_request_with_diffs, source_project: project, description: description) }

    it 'renders diffs and includes mermaid frame correctly' do
      visit(diffs_project_merge_request_path(project, merge_request))

      wait_for_requests

      page.within('.tab-content') do
        expect(page).to have_selector('.diffs')
      end

      visit(project_merge_request_path(project, merge_request))

      wait_for_requests

      page.within('.merge-request') do
        expect(page.html).to include(expected)
      end
    end
  end
end
