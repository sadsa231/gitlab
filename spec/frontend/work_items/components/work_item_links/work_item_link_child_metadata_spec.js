import { GlLabel, GlAvatarsInline } from '@gitlab/ui';

import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

import ItemMilestone from '~/issuable/components/issue_milestone.vue';
import WorkItemLinkChildMetadata from '~/work_items/components/work_item_links/work_item_link_child_metadata.vue';

import { workItemObjectiveMetadataWidgets } from '../../mock_data';

describe('WorkItemLinkChildMetadata', () => {
  const { MILESTONE, ASSIGNEES, LABELS } = workItemObjectiveMetadataWidgets;
  const mockMilestone = MILESTONE.milestone;
  const mockAssignees = ASSIGNEES.assignees.nodes;
  const mockLabels = LABELS.labels.nodes;
  let wrapper;

  const createComponent = ({ metadataWidgets = workItemObjectiveMetadataWidgets } = {}) => {
    wrapper = shallowMountExtended(WorkItemLinkChildMetadata, {
      propsData: {
        metadataWidgets,
      },
      slots: {
        default: `<div data-testid="default-slot">Foo</div>`,
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  it('renders default slot contents', () => {
    expect(wrapper.findByTestId('default-slot').text()).toBe('Foo');
  });

  it('renders item milestone', () => {
    const milestoneLink = wrapper.findComponent(ItemMilestone);

    expect(milestoneLink.exists()).toBe(true);
    expect(milestoneLink.props('milestone')).toEqual(mockMilestone);
  });

  it('renders avatars for assignees', () => {
    const avatars = wrapper.findComponent(GlAvatarsInline);

    expect(avatars.exists()).toBe(true);
    expect(avatars.props()).toMatchObject({
      avatars: mockAssignees,
      collapsed: true,
      maxVisible: 2,
      avatarSize: 24,
      badgeTooltipProp: 'name',
      badgeSrOnlyText: '',
    });
  });

  it('renders labels', () => {
    const labels = wrapper.findAllComponents(GlLabel);
    const mockLabel = mockLabels[0];

    expect(labels).toHaveLength(mockLabels.length);
    expect(labels.at(0).props()).toMatchObject({
      title: mockLabel.title,
      backgroundColor: mockLabel.color,
      description: mockLabel.description,
      scoped: false,
    });
    expect(labels.at(1).props('scoped')).toBe(true); // Second label is scoped
  });
});
