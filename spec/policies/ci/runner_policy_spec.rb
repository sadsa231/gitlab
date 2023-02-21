# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::RunnerPolicy, feature_category: :runner do
  describe 'ability :read_runner' do
    let_it_be(:guest) { create(:user) }
    let_it_be(:developer) { create(:user) }
    let_it_be(:maintainer) { create(:user) }
    let_it_be(:owner) { create(:user) }

    let_it_be_with_reload(:group) { create(:group, name: 'top-level', path: 'top-level') }
    let_it_be_with_reload(:subgroup) { create(:group, name: 'subgroup', path: 'subgroup', parent: group) }
    let_it_be_with_reload(:project) { create(:project, group: subgroup) }

    let_it_be(:instance_runner) { create(:ci_runner, :instance) }
    let_it_be(:group_runner) { create(:ci_runner, :group, groups: [group]) }
    let_it_be(:project_runner) { create(:ci_runner, :project, projects: [project]) }

    subject(:policy) { described_class.new(user, runner) }

    before_all do
      group.add_guest(guest)
      group.add_developer(developer)
      group.add_maintainer(maintainer)
      group.add_owner(owner)
    end

    shared_examples 'a policy allowing reading instance runner depending on runner sharing' do
      context 'with instance runner' do
        let(:runner) { instance_runner }

        it { expect_allowed :read_runner }

        context 'with shared runners disabled on projects' do
          before do
            project.update!(shared_runners_enabled: false)
          end

          it { expect_allowed :read_runner }
        end

        context 'with shared runners disabled for groups and projects' do
          before do
            group.update!(shared_runners_enabled: false)
            project.update!(shared_runners_enabled: false)
          end

          it { expect_disallowed :read_runner }
        end
      end
    end

    shared_examples 'a policy allowing reading group runner depending on runner sharing' do
      context 'with group runner' do
        let(:runner) { group_runner }

        it { expect_allowed :read_runner }

        context 'with sharing of group runners disabled' do
          before do
            project.update!(group_runners_enabled: false)
          end

          it { expect_disallowed :read_runner }
        end
      end
    end

    shared_examples 'does not allow reading runners on any scope' do
      context 'with instance runner' do
        let(:runner) { instance_runner }

        it { expect_disallowed :read_runner }

        context 'with shared runners disabled for groups and projects' do
          before do
            group.update!(shared_runners_enabled: false)
            project.update!(shared_runners_enabled: false)
          end

          it { expect_disallowed :read_runner }
        end
      end

      context 'with group runner' do
        let(:runner) { group_runner }

        it { expect_disallowed :read_runner }

        context 'with sharing of group runners disabled' do
          before do
            project.update!(group_runners_enabled: false)
          end

          it { expect_disallowed :read_runner }
        end
      end

      context 'with project runner' do
        let(:runner) { project_runner }

        it { expect_disallowed :read_runner }
      end
    end

    context 'without access' do
      let_it_be(:user) { create(:user) }

      it_behaves_like 'does not allow reading runners on any scope'
    end

    context 'with guest access' do
      let(:user) { guest }

      it_behaves_like 'does not allow reading runners on any scope'
    end

    context 'with developer access' do
      let(:user) { developer }

      it_behaves_like 'a policy allowing reading instance runner depending on runner sharing'

      it_behaves_like 'a policy allowing reading group runner depending on runner sharing'

      context 'with project runner' do
        let(:runner) { project_runner }

        it { expect_disallowed :read_runner }
      end
    end

    context 'with maintainer access' do
      let(:user) { maintainer }

      it_behaves_like 'a policy allowing reading instance runner depending on runner sharing'

      it_behaves_like 'a policy allowing reading group runner depending on runner sharing'

      context 'with project runner' do
        let(:runner) { project_runner }

        it { expect_allowed :read_runner }
      end
    end

    context 'with owner access' do
      let(:user) { owner }

      it_behaves_like 'a policy allowing reading instance runner depending on runner sharing'

      context 'with group runner' do
        let(:runner) { group_runner }

        it { expect_allowed :read_runner }

        context 'with sharing of group runners disabled' do
          before do
            project.update!(group_runners_enabled: false)
          end

          it { expect_allowed :read_runner }
        end
      end

      context 'with project runner' do
        let(:runner) { project_runner }

        it { expect_allowed :read_runner }
      end
    end
  end
end
