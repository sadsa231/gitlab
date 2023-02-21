import { GlDropdown, GlTruncate } from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import ImageFilter from 'ee/security_dashboard/components/shared/filters/image_filter.vue';
import QuerystringSync from 'ee/security_dashboard/components/shared/filters/querystring_sync.vue';
import DropdownButtonText from 'ee/security_dashboard/components/shared/filters/dropdown_button_text.vue';
import FilterItem from 'ee/security_dashboard/components/shared/filters/filter_item.vue';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import { ALL_ID } from 'ee/security_dashboard/components/shared/filters/constants';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/flash';
import createMockApollo from 'helpers/mock_apollo_helper';
import agentImagesQuery from 'ee/security_dashboard/graphql/queries/agent_images.query.graphql';
import projectImagesQuery from 'ee/security_dashboard/graphql/queries/project_images.query.graphql';
import { createMockDirective } from 'helpers/vue_mock_directive';
import { agentVulnerabilityImages, projectVulnerabilityImages } from '../../mock_data';

jest.mock('~/flash');
Vue.use(VueApollo);

describe('ImageFilter component', () => {
  let wrapper;
  const projectFullPath = 'test/path';
  const defaultQueryResolver = {
    agent: jest.fn().mockResolvedValue(agentVulnerabilityImages),
    project: jest.fn().mockResolvedValue(projectVulnerabilityImages),
  };
  const mockImages = projectVulnerabilityImages.data.project.vulnerabilityImages.nodes.map(
    ({ name }) => name,
  );

  const createWrapper = ({
    agentQueryResolver = defaultQueryResolver.agent,
    projectQueryResolver = defaultQueryResolver.project,
    provide = {},
  } = {}) => {
    wrapper = mountExtended(ImageFilter, {
      apolloProvider: createMockApollo([
        [agentImagesQuery, agentQueryResolver],
        [projectImagesQuery, projectQueryResolver],
      ]),
      provide: { projectFullPath, ...provide },
      directives: { GlTooltip: createMockDirective() },
      stubs: { QuerystringSync: true },
    });
  };

  const findQuerystringSync = () => wrapper.findComponent(QuerystringSync);
  const findDropdownItems = () => wrapper.findAllComponents(FilterItem);
  const findDropdownItem = (name) => wrapper.findByTestId(name);

  const clickDropdownItem = async (name) => {
    findDropdownItem(name).vm.$emit('click');
    await nextTick();
  };

  const expectSelectedItems = (ids) => {
    const checkedItems = findDropdownItems()
      .wrappers.filter((item) => item.props('isChecked'))
      .map((item) => item.attributes('data-testid'));

    expect(checkedItems).toEqual(ids);
  };

  const expectDropdownItem = (name) => {
    const item = findDropdownItem(name);
    const truncate = item.findComponent(GlTruncate);

    expect(item.props()).toMatchObject({
      isChecked: false,
      tooltip: name,
    });

    expect(truncate.attributes('title')).toBe('');
    expect(truncate.props()).toMatchObject({ text: name, position: 'middle' });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('basic structure', () => {
    beforeEach(async () => {
      createWrapper();
      await waitForPromises();
    });

    describe('QuerystringSync component', () => {
      it('has expected props', () => {
        expect(findQuerystringSync().props()).toMatchObject({
          querystringKey: 'image',
          value: [],
        });
      });

      it.each`
        emitted            | expected
        ${[]}              | ${[ALL_ID]}
        ${[mockImages[0]]} | ${[mockImages[0]]}
      `('restores selected items - $emitted', async ({ emitted, expected }) => {
        findQuerystringSync().vm.$emit('input', emitted);
        await nextTick();

        expectSelectedItems(expected);
      });
    });

    describe('default view', () => {
      it('shows the label', () => {
        expect(wrapper.find('label').text()).toBe(ImageFilter.i18n.label);
      });

      it('shows the dropdown with correct header text', () => {
        expect(wrapper.findComponent(GlDropdown).props('headerText')).toBe(ImageFilter.i18n.label);
      });

      it('shows the DropdownButtonText component with the correct props', () => {
        expect(wrapper.findComponent(DropdownButtonText).props()).toMatchObject({
          items: [ImageFilter.i18n.allItemsText],
          name: ImageFilter.i18n.label,
        });
      });
    });

    describe('filter-changed event', () => {
      it('emits filter-changed event when selected item is changed', async () => {
        const images = [];
        await clickDropdownItem(ALL_ID);

        expect(wrapper.emitted('filter-changed')[0][0].image).toEqual([]);

        for await (const image of mockImages) {
          await clickDropdownItem(image);
          images.push(image);

          expect(wrapper.emitted('filter-changed')[images.length][0].image).toEqual(images);
        }
      });
    });

    describe('dropdown items', () => {
      it('populates all dropdown items with correct text', () => {
        expect(findDropdownItems()).toHaveLength(mockImages.length + 1);
        expect(findDropdownItem(ALL_ID).text()).toBe(ImageFilter.i18n.allItemsText);
        mockImages.forEach((image) => expectDropdownItem(image));
      });

      it('allows multiple items to be selected', async () => {
        const images = [];

        for await (const image of mockImages) {
          await clickDropdownItem(image);
          images.push(image);

          expectSelectedItems(images);
        }
      });

      it('toggles the item selection when clicked on', async () => {
        for await (const image of mockImages) {
          await clickDropdownItem(image);

          expectSelectedItems([image]);

          await clickDropdownItem(image);

          expectSelectedItems([ALL_ID]);
        }
      });

      it('selects ALL item when created', () => {
        expectSelectedItems([ALL_ID]);
      });

      it('selects ALL item and deselects everything else when it is clicked', async () => {
        await clickDropdownItem(ALL_ID);
        await clickDropdownItem(ALL_ID); // Click again to verify that it doesn't toggle.

        expectSelectedItems([ALL_ID]);
      });

      it('deselects the ALL item when another item is clicked', async () => {
        await clickDropdownItem(ALL_ID);
        await clickDropdownItem(mockImages[0]);

        expectSelectedItems([mockImages[0]]);
      });
    });
  });

  describe('agent page', () => {
    const agentName = 'test-agent-name';

    beforeEach(async () => {
      createWrapper({ provide: { agentName } });
      await waitForPromises();
    });

    it('retrieves the options for the agent page', () => {
      expect(defaultQueryResolver.project).not.toHaveBeenCalled();
      expect(defaultQueryResolver.agent).toHaveBeenCalledTimes(1);
      expect(defaultQueryResolver.agent.mock.calls[0][0]).toEqual({
        agentName,
        projectPath: projectFullPath,
      });
    });

    it('populates all dropdown items with correct text', () => {
      expect(findDropdownItems()).toHaveLength(mockImages.length + 1);
      expect(findDropdownItem(ALL_ID).text()).toBe(ImageFilter.i18n.allItemsText);
      mockImages.forEach((image) => expectDropdownItem(image));
    });
  });

  it('shows an alert on a failed GraphQL request', async () => {
    createWrapper({ projectQueryResolver: jest.fn().mockRejectedValue() });
    await waitForPromises();

    expect(createAlert).toHaveBeenCalledWith({ message: ImageFilter.i18n.loadingError });
  });
});
