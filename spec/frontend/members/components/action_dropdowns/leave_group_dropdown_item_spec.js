import { GlDropdownItem } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import LeaveGroupDropdownItem from '~/members/components/action_dropdowns/leave_group_dropdown_item.vue';
import LeaveModal from '~/members/components/modals/leave_modal.vue';
import { LEAVE_MODAL_ID } from '~/members/constants';
import { member, permissions } from '../../mock_data';

describe('LeaveGroupDropdownItem', () => {
  let wrapper;
  const text = 'dummy';

  const createComponent = (propsData = {}) => {
    wrapper = shallowMount(LeaveGroupDropdownItem, {
      propsData: {
        member,
        permissions,
        ...propsData,
      },
      directives: {
        GlModal: createMockDirective(),
      },
      slots: {
        default: text,
      },
    });
  };

  const findDropdownItem = () => wrapper.findComponent(GlDropdownItem);

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders a slot with red text', () => {
    expect(findDropdownItem().html()).toContain(`<span class="gl-text-red-500">${text}</span>`);
  });

  it('contains LeaveModal component', () => {
    const leaveModal = wrapper.findComponent(LeaveModal);

    expect(leaveModal.props()).toEqual({ member, permissions });
  });

  it('binds to the LeaveModal component', () => {
    const binding = getBinding(findDropdownItem().element, 'gl-modal');

    expect(binding.value).toBe(LEAVE_MODAL_ID);
  });
});
