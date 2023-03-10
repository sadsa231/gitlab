import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import { setFaviconOverlay, resetFavicon } from '~/lib/utils/favicon';
import { setCiStatusFavicon } from '~/lib/utils/favicon_ci';
import { HTTP_STATUS_INTERNAL_SERVER_ERROR, HTTP_STATUS_OK } from '~/lib/utils/http_status';

jest.mock('~/lib/utils/favicon');

const TEST_URL = '/test/pipelinable/1';
const TEST_FAVICON = '/favicon.test.ico';

describe('~/lib/utils/favicon_ci', () => {
  let mock;

  beforeEach(() => {
    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    mock.restore();
    mock = null;
  });

  describe('setCiStatusFavicon', () => {
    it.each`
      response                     | setFaviconOverlayCalls | resetFaviconCalls
      ${{}}                        | ${[]}                  | ${[[]]}
      ${{ favicon: TEST_FAVICON }} | ${[[TEST_FAVICON]]}    | ${[]}
    `(
      'with response=$response',
      async ({ response, setFaviconOverlayCalls, resetFaviconCalls }) => {
        mock.onGet(TEST_URL).replyOnce(HTTP_STATUS_OK, response);

        expect(setFaviconOverlay).not.toHaveBeenCalled();
        expect(resetFavicon).not.toHaveBeenCalled();

        await setCiStatusFavicon(TEST_URL);

        expect(setFaviconOverlay.mock.calls).toEqual(setFaviconOverlayCalls);
        expect(resetFavicon.mock.calls).toEqual(resetFaviconCalls);
      },
    );

    it('with error', async () => {
      mock.onGet(TEST_URL).replyOnce(HTTP_STATUS_INTERNAL_SERVER_ERROR);

      await expect(setCiStatusFavicon(TEST_URL)).rejects.toEqual(expect.any(Error));
      expect(resetFavicon).toHaveBeenCalled();
    });
  });
});
