import { mount } from '@vue/test-utils';
import PanelResizer from '~/vue_shared/components/panel_resizer.vue';

describe('Panel Resizer component', () => {
  let wrapper;

  const triggerEvent = (eventName, el = wrapper.element, clientX = 0) => {
    const event = document.createEvent('MouseEvents');
    event.initMouseEvent(
      eventName,
      true,
      true,
      window,
      1,
      clientX,
      0,
      clientX,
      0,
      false,
      false,
      false,
      false,
      0,
      null,
    );

    el.dispatchEvent(event);
  };

  afterEach(() => {
    wrapper.destroy();
  });

  it('should render a div element with the correct classes and styles', () => {
    wrapper = mount(PanelResizer, {
      propsData: {
        startSize: 100,
        side: 'left',
      },
    });

    expect(wrapper.element.tagName).toEqual('DIV');
    expect(wrapper.classes().sort()).toStrictEqual([
      'drag-handle',
      'position-absolute',
      'position-bottom-0',
      'position-left-0',
      'position-top-0',
    ]);

    expect(wrapper.element.getAttribute('style')).toBe('cursor: ew-resize;');
  });

  it('should render a div element with the correct classes for a right side panel', () => {
    wrapper = mount(PanelResizer, {
      propsData: {
        startSize: 100,
        side: 'right',
      },
    });

    expect(wrapper.element.tagName).toEqual('DIV');
    expect(wrapper.classes().sort()).toStrictEqual([
      'drag-handle',
      'position-absolute',
      'position-bottom-0',
      'position-right-0',
      'position-top-0',
    ]);
  });

  it('drag the resizer', () => {
    wrapper = mount(PanelResizer, {
      propsData: {
        startSize: 100,
        side: 'left',
      },
    });

    triggerEvent('mousedown');
    triggerEvent('mousemove', document);
    triggerEvent('mouseup', document);

    expect(wrapper.emitted()).toEqual({
      'resize-start': [[100]],
      'update:size': [[100]],
      'resize-end': [[100]],
    });
  });
});
