# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Middleware::CompressedJson do
  let_it_be(:decompressed_input) { '{"foo": "bar"}' }
  let_it_be(:input) { ActiveSupport::Gzip.compress(decompressed_input) }

  let(:app) { double(:app) }
  let(:middleware) { described_class.new(app) }
  let(:content_type) { 'application/json' }
  let(:relative_url_root) { '/gitlab' }
  let(:env) do
    {
      'HTTP_CONTENT_ENCODING' => 'gzip',
      'REQUEST_METHOD' => 'POST',
      'CONTENT_TYPE' => content_type,
      'PATH_INFO' => path,
      'rack.input' => StringIO.new(input)
    }
  end

  shared_examples 'decompress middleware' do
    it 'replaces input with a decompressed content' do
      expect(app).to receive(:call)

      middleware.call(env)

      expect(env['rack.input'].read).to eq(decompressed_input)
      expect(env['CONTENT_LENGTH']).to eq(decompressed_input.length)
      expect(env['HTTP_CONTENT_ENCODING']).to be_nil
    end
  end

  shared_examples 'passes input' do
    it 'keeps the original input' do
      expect(app).to receive(:call)

      middleware.call(env)

      expect(env['rack.input'].read).to eq(input)
      expect(env['HTTP_CONTENT_ENCODING']).to eq('gzip')
    end
  end

  shared_context 'with relative url' do
    before do
      stub_config_setting(relative_url_root: relative_url_root)
    end
  end

  shared_examples 'handles non integer project ID' do
    context 'with a URL-encoded project ID' do
      let_it_be(:project_id) { 'gitlab-org%2fgitlab' }

      it_behaves_like 'decompress middleware'
    end

    context 'with a non URL-encoded project ID' do
      let_it_be(:project_id) { '1/repository/files/api/v4' }

      it_behaves_like 'passes input'
    end

    context 'with a blank project ID' do
      let_it_be(:project_id) { '' }

      it_behaves_like 'passes input'
    end
  end

  describe '#call' do
    context 'with collector route' do
      let(:path) { '/api/v4/error_tracking/collector/1/store' }

      it_behaves_like 'decompress middleware'

      context 'with no Content-Type' do
        let(:content_type) { nil }

        it_behaves_like 'decompress middleware'
      end

      include_context 'with relative url' do
        let(:path) { "#{relative_url_root}/api/v4/error_tracking/collector/1/store" }

        it_behaves_like 'decompress middleware'
      end
    end

    context 'with packages route' do
      context 'with instance level endpoint' do
        context 'with npm advisory bulk url' do
          let(:path) { '/api/v4/packages/npm/-/npm/v1/security/advisories/bulk' }

          it_behaves_like 'decompress middleware'

          include_context 'with relative url' do
            let(:path) { "#{relative_url_root}/api/v4/packages/npm/-/npm/v1/security/advisories/bulk" }

            it_behaves_like 'decompress middleware'
          end
        end

        context 'with npm quick audit url' do
          let(:path) { '/api/v4/packages/npm/-/npm/v1/security/audits/quick' }

          it_behaves_like 'decompress middleware'

          include_context 'with relative url' do
            let(:path) { "#{relative_url_root}/api/v4/packages/npm/-/npm/v1/security/audits/quick" }

            it_behaves_like 'decompress middleware'
          end
        end
      end

      context 'with project level endpoint' do
        let_it_be(:project_id) { 1 }

        context 'with npm advisory bulk url' do
          let(:path) { "/api/v4/projects/#{project_id}/packages/npm/-/npm/v1/security/advisories/bulk" }

          it_behaves_like 'decompress middleware'

          include_context 'with relative url' do
            let(:path) { "#{relative_url_root}/api/v4/projects/#{project_id}/packages/npm/-/npm/v1/security/advisories/bulk" } # rubocop disable Layout/LineLength

            it_behaves_like 'decompress middleware'
          end

          it_behaves_like 'handles non integer project ID'
        end

        context 'with npm quick audit url' do
          let(:path) { "/api/v4/projects/#{project_id}/packages/npm/-/npm/v1/security/audits/quick" }

          it_behaves_like 'decompress middleware'

          include_context 'with relative url' do
            let(:path) { "#{relative_url_root}/api/v4/projects/#{project_id}/packages/npm/-/npm/v1/security/audits/quick" } # rubocop disable Layout/LineLength

            it_behaves_like 'decompress middleware'
          end

          it_behaves_like 'handles non integer project ID'
        end
      end
    end

    context 'with some other route' do
      let(:path) { '/api/projects/123' }

      it_behaves_like 'passes input'
    end

    context 'payload is too large' do
      let(:body_limit) { Gitlab::Middleware::CompressedJson::MAXIMUM_BODY_SIZE }
      let(:decompressed_input) { 'a' * (body_limit + 100) }
      let(:input) { ActiveSupport::Gzip.compress(decompressed_input) }
      let(:path) { '/api/v4/error_tracking/collector/1/envelope' }

      it 'reads only limited size' do
        expect(middleware.call(env))
          .to eq([413, { 'Content-Type' => 'text/plain' }, ['Payload Too Large']])
      end
    end
  end
end
