import index from '~/sentry/legacy_index';

import LegacySentryConfig from '~/sentry/legacy_sentry_config';
import SentryConfig from '~/sentry/sentry_config';

describe('Sentry init', () => {
  let originalGon;

  const dsn = 'https://123@sentry.gitlab.test/123';
  const environment = 'test';
  const currentUserId = '1';
  const gitlabUrl = 'gitlabUrl';
  const revision = 'revision';
  const featureCategory = 'my_feature_category';

  beforeEach(() => {
    originalGon = window.gon;
    window.gon = {
      sentry_dsn: dsn,
      sentry_environment: environment,
      current_user_id: currentUserId,
      gitlab_url: gitlabUrl,
      revision,
      feature_category: featureCategory,
    };

    jest.spyOn(LegacySentryConfig, 'init').mockImplementation();
    jest.spyOn(SentryConfig, 'init').mockImplementation();
  });

  afterEach(() => {
    window.gon = originalGon;
  });

  it('exports legacy version of Sentry in the global object', () => {
    // eslint-disable-next-line no-underscore-dangle
    expect(window._Sentry.SDK_VERSION).toMatch(/^5\./);
  });

  describe('when called', () => {
    beforeEach(() => {
      index();
    });

    it('configures legacy sentry', () => {
      expect(LegacySentryConfig.init).toHaveBeenCalledTimes(1);
      expect(LegacySentryConfig.init).toHaveBeenCalledWith({
        dsn,
        currentUserId,
        whitelistUrls: [gitlabUrl, 'webpack-internal://'],
        environment,
        release: revision,
        tags: {
          revision,
          feature_category: featureCategory,
        },
      });
    });

    it('does not configure new sentry', () => {
      expect(SentryConfig.init).not.toHaveBeenCalled();
    });
  });
});
