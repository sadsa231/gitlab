import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import WorkItemDescriptionRendered from '~/work_items/components/work_item_description_rendered.vue';
import { renderGFM } from '~/behaviors/markdown/render_gfm';
import { descriptionTextWithCheckboxes, descriptionHtmlWithCheckboxes } from '../mock_data';

jest.mock('~/behaviors/markdown/render_gfm');

describe('WorkItemDescription', () => {
  let wrapper;

  const findEditButton = () => wrapper.find('[data-testid="edit-description"]');
  const findCheckboxAtIndex = (index) => wrapper.findAll('input[type="checkbox"]').at(index);

  const defaultWorkItemDescription = {
    description: descriptionTextWithCheckboxes,
    descriptionHtml: descriptionHtmlWithCheckboxes,
  };

  const createComponent = ({
    workItemDescription = defaultWorkItemDescription,
    canEdit = false,
  } = {}) => {
    wrapper = shallowMount(WorkItemDescriptionRendered, {
      propsData: {
        workItemDescription,
        canEdit,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders gfm', async () => {
    createComponent();

    await nextTick();

    expect(renderGFM).toHaveBeenCalled();
  });

  describe('with checkboxes', () => {
    beforeEach(() => {
      createComponent({
        canEdit: true,
        workItemDescription: {
          description: `- [x] todo 1\n- [ ] todo 2`,
          descriptionHtml: `<ul dir="auto" class="task-list" data-sourcepos="1:1-4:0">
<li class="task-list-item" data-sourcepos="1:1-2:15">
<input checked="" class="task-list-item-checkbox" type="checkbox"> todo 1</li>
<li class="task-list-item" data-sourcepos="2:1-2:15">
<input class="task-list-item-checkbox" type="checkbox"> todo 2</li>
</ul>`,
        },
      });
    });

    it('checks unchecked checkbox', async () => {
      findCheckboxAtIndex(1).setChecked();

      await nextTick();

      const updatedDescription = `- [x] todo 1\n- [x] todo 2`;
      expect(wrapper.emitted('descriptionUpdated')).toEqual([[updatedDescription]]);
    });

    it('disables checkbox while updating', async () => {
      findCheckboxAtIndex(1).setChecked();

      await nextTick();

      expect(findCheckboxAtIndex(1).attributes().disabled).toBeDefined();
    });

    it('unchecks checked checkbox', async () => {
      findCheckboxAtIndex(0).setChecked(false);

      await nextTick();

      const updatedDescription = `- [ ] todo 1\n- [ ] todo 2`;
      expect(wrapper.emitted('descriptionUpdated')).toEqual([[updatedDescription]]);
    });
  });

  describe('Edit button', () => {
    it('is not visible when canUpdate = false', async () => {
      await createComponent({
        canUpdate: false,
      });

      expect(findEditButton().exists()).toBe(false);
    });

    it('toggles edit mode', async () => {
      createComponent({
        canEdit: true,
      });

      findEditButton().vm.$emit('click');

      await nextTick();

      expect(wrapper.emitted('startEditing')).toEqual([[]]);
    });
  });
});
