# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Pipeline::Chain::PopulateMetadata do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user) { create(:user) }

  let(:pipeline) do
    build(:ci_pipeline, project: project, ref: 'master', user: user)
  end

  let(:command) do
    Gitlab::Ci::Pipeline::Chain::Command.new(
      project: project,
      current_user: user,
      origin_ref: 'master')
  end

  let(:dependencies) do
    [
      Gitlab::Ci::Pipeline::Chain::Config::Content.new(pipeline, command),
      Gitlab::Ci::Pipeline::Chain::Config::Process.new(pipeline, command),
      Gitlab::Ci::Pipeline::Chain::EvaluateWorkflowRules.new(pipeline, command),
      Gitlab::Ci::Pipeline::Chain::SeedBlock.new(pipeline, command),
      Gitlab::Ci::Pipeline::Chain::Seed.new(pipeline, command),
      Gitlab::Ci::Pipeline::Chain::Populate.new(pipeline, command)
    ]
  end

  let(:step) { described_class.new(pipeline, command) }

  let(:config) do
    { rspec: { script: 'rspec' } }
  end

  def run_chain
    dependencies.map(&:perform!)
    step.perform!
  end

  before do
    stub_ci_pipeline_yaml_file(YAML.dump(config))
  end

  context 'with pipeline name' do
    let(:config) do
      { workflow: { name: ' Pipeline name  ' }, rspec: { script: 'rspec' } }
    end

    it 'does not break the chain' do
      run_chain

      expect(step.break?).to be false
    end

    it 'builds pipeline_metadata' do
      run_chain

      expect(pipeline.pipeline_metadata.name).to eq('Pipeline name')
      expect(pipeline.pipeline_metadata.project).to eq(pipeline.project)
      expect(pipeline.pipeline_metadata).not_to be_persisted
    end

    context 'with empty name' do
      let(:config) do
        { workflow: { name: '  ' }, rspec: { script: 'rspec' } }
      end

      it 'strips whitespace from name' do
        run_chain

        expect(pipeline.pipeline_metadata).to be_nil
      end

      context 'with empty name after variable substitution' do
        let(:config) do
          { workflow: { name: '$VAR1' }, rspec: { script: 'rspec' } }
        end

        it 'does not save empty name' do
          run_chain

          expect(pipeline.pipeline_metadata).to be_nil
        end
      end
    end

    context 'with variables' do
      let(:config) do
        {
          variables: { ROOT_VAR: 'value $WORKFLOW_VAR1' },
          workflow: {
            name: 'Pipeline $ROOT_VAR $WORKFLOW_VAR2 $UNKNOWN_VAR',
            rules: [{ variables: { WORKFLOW_VAR1: 'value1', WORKFLOW_VAR2: 'value2' } }]
          },
          rspec: { script: 'rspec' }
        }
      end

      it 'substitutes variables' do
        run_chain

        expect(pipeline.pipeline_metadata.name).to eq('Pipeline value value1 value2')
      end
    end

    context 'with invalid name' do
      let(:config) do
        {
          variables: { ROOT_VAR: 'a' * 256 },
          workflow: {
            name: 'Pipeline $ROOT_VAR'
          },
          rspec: { script: 'rspec' }
        }
      end

      it 'returns error and breaks chain' do
        ret = run_chain

        expect(ret)
          .to match_array(["Failed to build pipeline metadata! Name is too long (maximum is 255 characters)"])
        expect(pipeline.pipeline_metadata.errors.full_messages)
          .to match_array(['Name is too long (maximum is 255 characters)'])
        expect(step.break?).to be true
      end
    end
  end
end
