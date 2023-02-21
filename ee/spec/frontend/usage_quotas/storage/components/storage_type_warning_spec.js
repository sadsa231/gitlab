import { nextTick } from 'vue';
import { GlPopover } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import StorageTypeWarning from 'ee/usage_quotas/storage/components/storage_type_warning.vue';

let wrapper;

const createComponent = (props = {}) => {
  wrapper = shallowMount(StorageTypeWarning, {
    propsData: {
      ...props,
    },
  });
};

const findGlPopover = () => wrapper.findComponent(GlPopover);

describe('StorageTypeWarning', () => {
  const content = 'Bucha';

  beforeEach(async () => {
    createComponent({ content });
    await nextTick();
  });

  it('will display a popover', () => {
    expect(findGlPopover().exists()).toBe(true);
  });

  it('will pass through content to popover', () => {
    expect(findGlPopover().attributes('content')).toBe(content);
  });
});
