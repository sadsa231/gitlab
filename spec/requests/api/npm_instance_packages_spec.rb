# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::NpmInstancePackages, feature_category: :package_registry do
  # We need to create a subgroup with the same name as the hosting group.
  # It has to be created first to exhibit this bug: https://gitlab.com/gitlab-org/gitlab/-/issues/321958
  let_it_be(:another_namespace) { create(:group, :public) }
  let_it_be(:similarly_named_group) { create(:group, :public, parent: another_namespace, name: 'test-group') }

  include_context 'npm api setup'

  describe 'GET /api/v4/packages/npm/*package_name' do
    it_behaves_like 'handling get metadata requests', scope: :instance do
      let(:url) { api("/packages/npm/#{package_name}") }
    end
  end

  describe 'GET /api/v4/packages/npm/-/package/*package_name/dist-tags' do
    it_behaves_like 'handling get dist tags requests', scope: :instance do
      let(:url) { api("/packages/npm/-/package/#{package_name}/dist-tags") }
    end
  end

  describe 'PUT /api/v4/packages/npm/-/package/*package_name/dist-tags/:tag' do
    it_behaves_like 'handling create dist tag requests', scope: :instance do
      let(:url) { api("/packages/npm/-/package/#{package_name}/dist-tags/#{tag_name}") }
    end
  end

  describe 'DELETE /api/v4/packages/npm/-/package/*package_name/dist-tags/:tag' do
    it_behaves_like 'handling delete dist tag requests', scope: :instance do
      let(:url) { api("/packages/npm/-/package/#{package_name}/dist-tags/#{tag_name}") }
    end
  end

  describe 'POST /api/v4/packages/npm/-/npm/v1/security/advisories/bulk' do
    it_behaves_like 'handling audit request', path: 'advisories/bulk', scope: :instance do
      let(:url) { api('/packages/npm/-/npm/v1/security/advisories/bulk') }
    end
  end

  describe 'POST /api/v4/packages/npm/-/npm/v1/security/audits/quick' do
    it_behaves_like 'handling audit request', path: 'audits/quick', scope: :instance do
      let(:url) { api('/packages/npm/-/npm/v1/security/audits/quick') }
    end
  end
end
