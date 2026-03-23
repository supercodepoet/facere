require "application_system_test_case"

class TodoItemDetailTest < ApplicationSystemTestCase
  setup do
    @user = User.create!(
      name: "Detail Test",
      email_address: "detail_test@example.com",
      password: "Password1!",
      password_confirmation: "Password1!",
      terms_accepted_at: Time.current,
      email_verified_at: Time.current
    )
    @todo_list = @user.todo_lists.create!(name: "Weekend Project", color: "purple", template: "blank")
    @todo_item = @todo_list.todo_items.create!(
      name: "Design new landing page mockups",
      position: 0,
      status: "todo",
      priority: "none"
    )

    visit sign_in_path
    set_wa_input("email_address", "detail_test@example.com")
    set_wa_input("password", "Password1!")
    page.execute_script("document.querySelector('form').requestSubmit()")
    assert_no_text "Welcome back!", wait: 10
  end

  test "viewing item detail page shows two-column layout" do
    visit todo_list_todo_item_path(@todo_list, @todo_item)
    assert_text "Design new landing page mockups"
    assert_text "Weekend Project"
    assert_text "Status"
    assert_text "PRIORITY"
    assert_text "Notes"
    assert_text "Checklist"
    assert_text "Attachments"
    assert_text "Comments"
  end

  test "status selector shows all four options" do
    visit todo_list_todo_item_path(@todo_list, @todo_item)
    assert_text "To Do"
    assert_text "In Progress"
    assert_text "On Hold"
    assert_text "Done"
  end

  test "priority selector shows all five options" do
    visit todo_list_todo_item_path(@todo_list, @todo_item)
    assert_text "Urgent"
    assert_text "High"
    assert_text "Medium"
    assert_text "Low"
    assert_text "None"
  end

  private

  def set_wa_input(name, value)
    find("wa-input[name='#{name}']", wait: 5)
    page.execute_script <<~JS
      const input = document.querySelector('wa-input[name="#{name}"]');
      input.value = '#{value}';
      input.dispatchEvent(new Event('wa-input', { bubbles: true }));
      input.dispatchEvent(new Event('wa-change', { bubbles: true }));
      input.dispatchEvent(new Event('input', { bubbles: true }));
      input.dispatchEvent(new Event('change', { bubbles: true }));
    JS
  end
end
