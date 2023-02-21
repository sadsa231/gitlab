# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::DependencyProxyManifestRegistry, :geo, type: :model do
  let_it_be(:registry) { create(:geo_dependency_proxy_manifest_registry) }

  specify 'factory is valid' do
    expect(registry).to be_valid
  end

  include_examples 'a Geo framework registry'
  include_examples 'a Geo verifiable registry'
end
