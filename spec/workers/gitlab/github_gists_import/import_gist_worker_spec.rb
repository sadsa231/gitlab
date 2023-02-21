# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubGistsImport::ImportGistWorker, feature_category: :importers do
  subject { described_class.new }

  let_it_be(:user) { create(:user) }
  let(:token) { 'token' }
  let(:gist_hash) do
    {
      id: '055b70',
      git_pull_url: 'https://gist.github.com/foo/bar.git',
      files: {
        'random.txt': {
          filename: 'random.txt',
          type: 'text/plain',
          language: 'Text',
          raw_url: 'https://gist.githubusercontent.com/user_name/055b70/raw/66a7be0d/random.txt',
          size: 166903
        }
      },
      is_public: false,
      created_at: '2022-09-06T11:38:18Z',
      updated_at: '2022-09-06T11:38:18Z',
      description: 'random text'
    }
  end

  let(:importer) { instance_double('Gitlab::GithubGistsImport::Importer::GistImporter') }
  let(:importer_result) { instance_double('ServiceResponse', success?: true) }
  let(:gist_object) do
    instance_double('Gitlab::GithubGistsImport::Representation::Gist',
      gist_hash.merge(github_identifiers: { id: '055b70' }, truncated_title: 'random text', visibility_level: 0))
  end

  let(:log_attributes) do
    {
      'user_id' => user.id,
      'github_identifiers' => { 'id': gist_object.id },
      'class' => 'Gitlab::GithubGistsImport::ImportGistWorker',
      'correlation_id' => 'new-correlation-id',
      'jid' => nil,
      'job_status' => 'running',
      'queue' => 'github_gists_importer:github_gists_import_import_gist'
    }
  end

  describe '#perform' do
    before do
      allow(Gitlab::GithubGistsImport::Representation::Gist)
        .to receive(:from_json_hash)
        .with(gist_hash)
        .and_return(gist_object)

      allow(Gitlab::GithubGistsImport::Importer::GistImporter)
        .to receive(:new)
        .with(gist_object, user.id)
        .and_return(importer)

      allow(Gitlab::ApplicationContext).to receive(:current).and_return('correlation_id' => 'new-correlation-id')
      allow(described_class).to receive(:queue).and_return('github_gists_importer:github_gists_import_import_gist')
    end

    context 'when success' do
      it 'imports gist' do
        expect(Gitlab::GithubImport::Logger)
          .to receive(:info)
          .with(log_attributes.merge('message' => 'start importer'))
        expect(importer).to receive(:execute).and_return(importer_result)
        expect(Gitlab::JobWaiter).to receive(:notify).with('some_key', subject.jid)
        expect(Gitlab::GithubImport::Logger)
          .to receive(:info)
          .with(log_attributes.merge('message' => 'importer finished'))

        subject.perform(user.id, gist_hash, 'some_key')
      end
    end

    context 'when importer raised an error' do
      it 'raises an error' do
        exception = StandardError.new('_some_error_')

        expect(importer).to receive(:execute).and_raise(exception)
        expect(Gitlab::GithubImport::Logger)
          .to receive(:error)
          .with(log_attributes.merge('message' => 'importer failed', 'error.message' => '_some_error_'))
        expect(Gitlab::ErrorTracking).to receive(:track_exception)

        expect { subject.perform(user.id, gist_hash, 'some_key') }.to raise_error(StandardError)
      end
    end
  end
end
