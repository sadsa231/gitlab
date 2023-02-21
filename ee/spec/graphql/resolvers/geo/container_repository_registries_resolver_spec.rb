# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::Geo::ContainerRepositoryRegistriesResolver do
  it_behaves_like 'a Geo registries resolver', :geo_container_repository_registry
end
