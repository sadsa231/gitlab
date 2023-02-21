# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::Projects::Menus::RepositoryMenu, feature_category: :source_code_management do
  let_it_be(:project) { create(:project, :repository) }

  let(:user) { project.first_owner }
  let(:context) { Sidebars::Projects::Context.new(current_user: user, container: project, current_ref: 'master') }

  subject { described_class.new(context) }

  describe '#render?' do
    context 'when project repository is empty' do
      it 'returns false' do
        allow(project).to receive(:empty_repo?).and_return(true)

        expect(subject.render?).to eq false
      end
    end

    context 'when project repository is not empty' do
      context 'when user can download code' do
        it 'returns true' do
          expect(subject.render?).to eq true
        end
      end

      context 'when user cannot download code' do
        let(:user) { nil }

        it 'returns false' do
          expect(subject.render?).to eq false
        end
      end
    end

    context 'for menu items' do
      shared_examples_for 'repository menu item link for' do |item_id|
        let(:ref) { 'master' }
        let(:item_id) { item_id }
        subject { described_class.new(context).renderable_items.find { |e| e.item_id == item_id }.link }

        using RSpec::Parameterized::TableSyntax

        let(:context) do
          Sidebars::Projects::Context.new(current_user: user, container: project, current_ref: ref,
                                          ref_type: ref_type)
        end

        where(:feature_flag_enabled, :ref_type, :link) do
          true  | nil     | lazy { "#{route}?ref_type=heads" }
          true  | 'heads' | lazy { "#{route}?ref_type=heads" }
          true  | 'tags'  | lazy { "#{route}?ref_type=tags" }
          false | nil     | lazy { route }
          false | 'heads' | lazy { route }
          false | 'tags'  | lazy { route }
        end

        with_them do
          before do
            stub_feature_flags(use_ref_type_parameter: feature_flag_enabled)
          end

          it 'has a link with the fully qualifed ref route' do
            expect(subject).to eq(link)
          end
        end

        context 'when ref is not the default' do
          let(:ref) { 'nonmain' }

          context 'and ref_type is not provided' do
            let(:ref_type) { nil }

            it { is_expected.to eq(route) }
          end

          context 'and ref_type is provided' do
            let(:ref_type) { 'heads' }

            it { is_expected.to eq("#{route}?ref_type=heads") }
          end
        end
      end

      describe 'Commits' do
        let_it_be(:item_id) { :commits }

        it_behaves_like 'repository menu item link for', :commits do
          let(:route) { "/#{project.full_path}/-/commits/#{ref}" }
        end
      end

      describe 'Contributors' do
        let_it_be(:item_id) { :contributors }

        context 'when analytics is disabled' do
          subject { described_class.new(context).renderable_items.find { |e| e.item_id == item_id } }

          before do
            project.project_feature.update!(analytics_access_level: ProjectFeature::DISABLED)
          end

          it { is_expected.to be_nil }
        end

        context 'when analytics is enabled' do
          before do
            project.project_feature.update!(analytics_access_level: ProjectFeature::ENABLED)
          end

          it_behaves_like 'repository menu item link for', :contributors do
            let(:route) { "/#{project.full_path}/-/graphs/#{ref}" }
          end
        end
      end

      describe 'Network' do
        it_behaves_like 'repository menu item link for', :graphs do
          let(:route) { "/#{project.full_path}/-/network/#{ref}" }
        end
      end
    end
  end
end
