# frozen_string_literal: true

module ListboxHelpers
  def select_from_listbox(text, from:, exact_item_text: false)
    click_button from
    select_listbox_item(text, exact_text: exact_item_text)
  end

  def select_listbox_item(text, exact_text: false)
    find('.gl-dropdown-item[role="option"]', text: text, exact_text: exact_text).click
  end

  def expect_listbox_item(text)
    expect(page).to have_css('.gl-dropdown-item[role="option"]', text: text)
  end

  def expect_no_listbox_item(text)
    expect(page).not_to have_css('.gl-dropdown-item[role="option"]', text: text)
  end

  def expect_listbox_items(items)
    expect(find_all('.gl-dropdown-item[role="option"]').map(&:text)).to eq(items)
  end
end
