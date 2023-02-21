# frozen_string_literal: true

require 'spec_helper'

RSpec.shared_examples "redis_new_instance_shared_examples" do |name, fallback_class|
  include TmpdirHelper

  let(:instance_specific_config_file) { "config/redis.#{name}.yml" }
  let(:environment_config_file_name) { "GITLAB_REDIS_#{name.upcase}_CONFIG_FILE" }
  let(:fallback_config_file) { nil }
  let(:rails_root) { mktmpdir }

  before do
    allow(fallback_class).to receive(:config_file_name).and_return(fallback_config_file)
  end

  it_behaves_like "redis_shared_examples"

  describe '.config_file_name' do
    subject { described_class.config_file_name }

    before do
      # Undo top-level stub of config_file_name because we are testing that method now.
      allow(described_class).to receive(:config_file_name).and_call_original

      allow(described_class).to receive(:rails_root).and_return(rails_root)
      FileUtils.mkdir_p(File.join(rails_root, 'config'))
    end

    context 'when there is only a resque.yml' do
      before do
        FileUtils.touch(File.join(rails_root, 'config/resque.yml'))
      end

      it { expect(subject).to eq("#{rails_root}/config/resque.yml") }

      context 'and there is a global env override' do
        before do
          stub_env('GITLAB_REDIS_CONFIG_FILE', 'global override')
        end

        it { expect(subject).to eq('global override') }

        context "and #{fallback_class.name.demodulize} has a different config file" do
          let(:fallback_config_file) { 'fallback config file' }

          it { expect(subject).to eq('fallback config file') }
        end
      end
    end
  end

  describe '#fetch_config' do
    context 'when redis.yml exists' do
      subject { described_class.new('test').send(:fetch_config) }

      before do
        allow(described_class).to receive(:config_file_name).and_call_original
        allow(described_class).to receive(:redis_yml_path).and_call_original
        allow(described_class).to receive(:rails_root).and_return(rails_root)
        FileUtils.mkdir_p(File.join(rails_root, 'config'))
      end

      context 'when the fallback has a redis.yml entry' do
        before do
          File.write(File.join(rails_root, 'config/redis.yml'), {
            'test' => {
              described_class.config_fallback.store_name.underscore => { 'fallback redis.yml' => 123 }
            }
          }.to_json)
        end

        it { expect(subject).to eq({ 'fallback redis.yml' => 123 }) }

        context 'and an instance config file exists' do
          before do
            File.write(File.join(rails_root, instance_specific_config_file), {
              'test' => { 'instance specific file' => 456 }
            }.to_json)
          end

          it { expect(subject).to eq({ 'instance specific file' => 456 }) }

          context 'and the instance has a redis.yml entry' do
            before do
              File.write(File.join(rails_root, 'config/redis.yml'), {
                'test' => { name => { 'instance redis.yml' => 789 } }
              }.to_json)
            end

            it { expect(subject).to eq({ 'instance redis.yml' => 789 }) }
          end
        end
      end
    end
  end
end
