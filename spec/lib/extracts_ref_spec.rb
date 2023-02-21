# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ExtractsRef do
  include described_class
  include RepoHelpers

  let_it_be(:owner) { create(:user) }
  let_it_be(:container) { create(:snippet, :repository, author: owner) }

  let(:ref) { sample_commit[:id] }
  let(:path) { sample_commit[:line_code_path] }
  let(:params) { ActionController::Parameters.new(path: path, ref: ref) }

  before do
    ref_names = ['master', 'foo/bar/baz', 'v1.0.0', 'v2.0.0', 'release/app', 'release/app/v1.0.0']

    allow(container.repository).to receive(:ref_names).and_return(ref_names)
    allow_any_instance_of(described_class).to receive(:repository_container).and_return(container)
  end

  describe '#assign_ref_vars' do
    it_behaves_like 'assigns ref vars'

    context 'ref and path are nil' do
      let(:ref) { nil }
      let(:path) { nil }

      it 'does not set commit' do
        expect(container.repository).not_to receive(:commit).with('')

        assign_ref_vars

        expect(@commit).to be_nil
      end
    end

    context 'when ref and path have incorrect format' do
      let(:ref) { { wrong: :format } }
      let(:path) { { also: :wrong } }

      it 'does not raise an exception' do
        expect { assign_ref_vars }.not_to raise_error
      end
    end

    context 'when a ref_type parameter is provided' do
      let(:params) { ActionController::Parameters.new(path: path, ref: ref, ref_type: 'tags') }

      context 'and the use_ref_type_parameter feature flag is enabled' do
        it 'sets a fully_qualified_ref variable' do
          fully_qualified_ref = "refs/tags/#{ref}"
          expect(container.repository).to receive(:commit).with(fully_qualified_ref)
          assign_ref_vars
          expect(@fully_qualified_ref).to eq(fully_qualified_ref)
        end
      end
    end
  end

  it_behaves_like 'extracts refs'
end
