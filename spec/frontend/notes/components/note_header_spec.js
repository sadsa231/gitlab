import Vue, { nextTick } from 'vue';
import Vuex from 'vuex';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import NoteHeader from '~/notes/components/note_header.vue';

Vue.use(Vuex);

const actions = {
  setTargetNoteHash: jest.fn(),
};

describe('NoteHeader component', () => {
  let wrapper;

  const findActionsWrapper = () => wrapper.findComponent({ ref: 'discussionActions' });
  const findToggleThreadButton = () => wrapper.findByTestId('thread-toggle');
  const findChevronIcon = () => wrapper.findComponent({ ref: 'chevronIcon' });
  const findActionText = () => wrapper.findComponent({ ref: 'actionText' });
  const findTimestampLink = () => wrapper.findComponent({ ref: 'noteTimestampLink' });
  const findTimestamp = () => wrapper.findComponent({ ref: 'noteTimestamp' });
  const findInternalNoteIndicator = () => wrapper.findByTestId('internal-note-indicator');
  const findSpinner = () => wrapper.findComponent({ ref: 'spinner' });

  const statusHtml =
    '"<span class="user-status-emoji has-tooltip" title="foo bar" data-html="true" data-placement="top"><gl-emoji title="basketball and hoop" data-name="basketball" data-unicode-version="6.0">🏀</gl-emoji></span>"';

  const author = {
    avatar_url: null,
    id: 1,
    name: 'Root',
    path: '/root',
    state: 'active',
    username: 'root',
    show_status: true,
    status_tooltip_html: statusHtml,
  };

  const createComponent = (props) => {
    wrapper = shallowMountExtended(NoteHeader, {
      store: new Vuex.Store({
        actions,
      }),
      propsData: { ...props },
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  it('does not render discussion actions when includeToggle is false', () => {
    createComponent({
      includeToggle: false,
    });

    expect(findActionsWrapper().exists()).toBe(false);
  });

  describe('when includes a toggle', () => {
    it('renders discussion actions', () => {
      createComponent({
        includeToggle: true,
      });

      expect(findActionsWrapper().exists()).toBe(true);
    });

    it('emits toggleHandler event on button click', () => {
      createComponent({
        includeToggle: true,
      });

      wrapper.find('.note-action-button').trigger('click');
      expect(wrapper.emitted('toggleHandler')).toBeDefined();
      expect(wrapper.emitted('toggleHandler')).toHaveLength(1);
    });

    it('has chevron-up icon if expanded prop is true', () => {
      createComponent({
        includeToggle: true,
        expanded: true,
      });

      expect(findChevronIcon().props('name')).toBe('chevron-up');
    });

    it('has chevron-down icon if expanded prop is false', () => {
      createComponent({
        includeToggle: true,
        expanded: false,
      });

      expect(findChevronIcon().props('name')).toBe('chevron-down');
    });

    it.each`
      text                          | expanded
      ${NoteHeader.i18n.showThread} | ${false}
      ${NoteHeader.i18n.hideThread} | ${true}
    `('toggle button has text $text is expanded is $expanded', ({ text, expanded }) => {
      createComponent({
        includeToggle: true,
        expanded,
      });

      expect(findToggleThreadButton().text()).toBe(text);
    });
  });

  it('renders an author link if author is passed to props', () => {
    createComponent({ author });

    expect(wrapper.find('.js-user-link').exists()).toBe(true);
  });
  it('renders deleted user text if author is not passed as a prop', () => {
    createComponent();

    expect(wrapper.text()).toContain('A deleted user');
  });

  it('does not render created at information if createdAt is not passed as a prop', () => {
    createComponent();

    expect(findActionText().exists()).toBe(false);
    expect(findTimestampLink().exists()).toBe(false);
  });

  describe('when createdAt is passed as a prop', () => {
    it('renders action text and a timestamp', () => {
      createComponent({
        createdAt: '2017-08-02T10:51:58.559Z',
        noteId: 123,
      });

      expect(findActionText().exists()).toBe(true);
      expect(findTimestampLink().exists()).toBe(true);
    });

    it('renders correct actionText if passed', () => {
      createComponent({
        createdAt: '2017-08-02T10:51:58.559Z',
        actionText: 'Test action text',
      });

      expect(findActionText().text()).toBe('Test action text');
    });

    it('calls an action when timestamp is clicked', () => {
      createComponent({
        createdAt: '2017-08-02T10:51:58.559Z',
        noteId: 123,
      });
      findTimestampLink().trigger('click');

      expect(actions.setTargetNoteHash).toHaveBeenCalled();
    });
  });

  describe('loading spinner', () => {
    it('shows spinner when showSpinner is true', () => {
      createComponent();
      expect(findSpinner().exists()).toBe(true);
    });

    it('does not show spinner when showSpinner is false', () => {
      createComponent({ showSpinner: false });
      expect(findSpinner().exists()).toBe(false);
    });
  });

  describe('timestamp', () => {
    it('shows timestamp as a link if a noteId was provided', () => {
      createComponent({ createdAt: new Date().toISOString(), noteId: 123 });
      expect(findTimestampLink().exists()).toBe(true);
      expect(findTimestamp().exists()).toBe(false);
    });

    it('shows timestamp as plain text if a noteId was not provided', () => {
      createComponent({ createdAt: new Date().toISOString() });
      expect(findTimestampLink().exists()).toBe(false);
      expect(findTimestamp().exists()).toBe(true);
    });
  });

  describe('author username link', () => {
    it('proxies `mouseenter` event to author name link', () => {
      createComponent({ author });

      const dispatchEvent = jest.spyOn(wrapper.vm.$refs.authorNameLink, 'dispatchEvent');

      wrapper.findComponent({ ref: 'authorUsernameLink' }).trigger('mouseenter');

      expect(dispatchEvent).toHaveBeenCalledWith(new Event('mouseenter'));
    });

    it('proxies `mouseleave` event to author name link', () => {
      createComponent({ author });

      const dispatchEvent = jest.spyOn(wrapper.vm.$refs.authorNameLink, 'dispatchEvent');

      wrapper.findComponent({ ref: 'authorUsernameLink' }).trigger('mouseleave');

      expect(dispatchEvent).toHaveBeenCalledWith(new Event('mouseleave'));
    });
  });

  describe('when author username link is hovered', () => {
    it('toggles hover specific CSS classes on author name link', async () => {
      createComponent({ author });

      const authorUsernameLink = wrapper.findComponent({ ref: 'authorUsernameLink' });
      const authorNameLink = wrapper.findComponent({ ref: 'authorNameLink' });

      authorUsernameLink.trigger('mouseenter');

      await nextTick();
      expect(authorNameLink.classes()).toContain('hover');
      expect(authorNameLink.classes()).toContain('text-underline');

      authorUsernameLink.trigger('mouseleave');

      await nextTick();
      expect(authorNameLink.classes()).not.toContain('hover');
      expect(authorNameLink.classes()).not.toContain('text-underline');
    });
  });

  describe('with internal note badge', () => {
    it.each`
      status   | condition
      ${true}  | ${'shows'}
      ${false} | ${'hides'}
    `('$condition badge when isInternalNote is $status', ({ status }) => {
      createComponent({ isInternalNote: status });
      expect(findInternalNoteIndicator().exists()).toBe(status);
    });

    it('shows internal note badge tooltip for project context', () => {
      createComponent({ isInternalNote: true, noteableType: 'issue' });

      expect(findInternalNoteIndicator().attributes('title')).toBe(
        'This internal note will always remain confidential',
      );
    });
  });

  it('does render username', () => {
    createComponent({ author }, true);

    expect(wrapper.find('.note-header-info').text()).toContain('@');
  });

  describe('with system note', () => {
    it('does not render username', () => {
      createComponent({ author, isSystemNote: true }, true);

      expect(wrapper.find('.note-header-info').text()).not.toContain('@');
    });
  });
});
