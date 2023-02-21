import { GlSingleStat } from '@gitlab/ui/dist/charts';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import SingleStat from 'ee/product_analytics/dashboards/components/visualizations/single_stat.vue';

describe('Single Stat Visualization', () => {
  let wrapper;

  const findSingleStat = () => wrapper.findComponent(GlSingleStat);

  const createWrapper = (props = {}) => {
    wrapper = mountExtended(SingleStat, {
      propsData: {
        data: props.data,
        options: props.options,
      },
    });
  };

  describe('when mounted', () => {
    it('should render the single stat with default props', () => {
      createWrapper();

      expect(findSingleStat().props()).toMatchObject({
        value: 0,
        title: '',
        variant: 'muted',
        shouldAnimate: true,
        animationDecimalPlaces: 0,
      });
    });

    it('should pass the visualization data to the single stat value', () => {
      createWrapper({ data: 35 });

      expect(findSingleStat().props('value')).toBe(35);
    });

    it('should pass the visualization options to the single stat', () => {
      const options = {
        title: 'Sessions',
        decimalPlaces: 2,
        metaText: 'meta text',
        metaIcon: 'project',
        titleIcon: 'users',
        unit: 'days',
      };
      createWrapper({ options });

      expect(findSingleStat().props()).toMatchObject({
        title: 'Sessions',
        metaText: 'meta text',
        metaIcon: 'project',
        titleIcon: 'users',
        unit: 'days',
        animationDecimalPlaces: 2,
      });
    });
  });
});
