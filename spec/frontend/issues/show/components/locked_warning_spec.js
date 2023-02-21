import { GlAlert, GlLink } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import { sprintf } from '~/locale';
import { IssuableType } from '~/issues/constants';
import LockedWarning, { i18n } from '~/issues/show/components/locked_warning.vue';

describe('LockedWarning component', () => {
  let wrapper;

  const createComponent = (props = {}) => {
    wrapper = mountExtended(LockedWarning, {
      propsData: props,
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  const findAlert = () => wrapper.findComponent(GlAlert);
  const findLink = () => wrapper.findComponent(GlLink);

  describe.each([IssuableType.Issue, IssuableType.Epic])(
    'with issuableType set to %s',
    (issuableType) => {
      let alert;
      let link;
      beforeEach(() => {
        createComponent({ issuableType });
        alert = findAlert();
        link = findLink();
      });

      afterEach(() => {
        alert = null;
        link = null;
      });

      it('displays a non-closable alert', () => {
        expect(alert.exists()).toBe(true);
        expect(alert.props('dismissible')).toBe(false);
      });

      it(`displays correct message`, async () => {
        expect(alert.text()).toMatchInterpolatedText(sprintf(i18n.alertMessage, { issuableType }));
      });

      it(`displays a link with correct text`, async () => {
        expect(link.exists()).toBe(true);
        expect(link.text()).toBe(`the ${issuableType}`);
      });
    },
  );
});
