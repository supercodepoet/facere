require "application_system_test_case"

class TodoListsTest < ApplicationSystemTestCase
  setup do
    @user = User.create!(
      name: "System Test",
      email_address: "system@example.com",
      password: "Password1!",
      password_confirmation: "Password1!",
      terms_accepted_at: Time.current,
      email_verified_at: Time.current
    )

    # Sign in — wa-input uses FormData, need to set value + dispatch wa-change
    visit sign_in_path
    set_wa_input("email_address", "system@example.com")
    set_wa_input("password", "Password1!")
    sleep 0.3
    page.execute_script("document.querySelector('form').requestSubmit()")
    assert_no_text "Welcome back!", wait: 5
  end

  test "viewing blank slate when no lists" do
    assert_text "Your lists are waiting!"
    assert_link "Create My First List"
  end

  test "creating a new list with blank template" do
    click_link "Create My First List"
    assert_text "Create a new list"

    set_wa_input_by_id("todo_list_name", "My First List")
    click_wa_button("Create List")

    assert_text "List created successfully", wait: 5
    assert_text "My First List"
    assert_text "Your list is ready"
  end

  test "creating a list with project template" do
    click_link "Create My First List"
    assert_text "Create a new list"

    set_wa_input_by_id("todo_list_name", "Project Plan")
    # Set the template hidden input directly since wa-button + Stimulus may not wire up
    page.execute_script <<~JS
      document.querySelector('input[name="todo_list[template]"]').value = 'project';
    JS
    click_wa_button("Create List")

    assert_text "List created successfully", wait: 5
    assert_text "Planning"
    assert_text "Define project scope"
  end

  test "viewing list overview with existing lists" do
    @user.todo_lists.create!(name: "Shopping", color: "green", template: "blank")
    @user.todo_lists.create!(name: "Work Tasks", color: "blue", template: "blank")
    visit todo_lists_path

    assert_text "My Lists"
    assert_text "Shopping"
    assert_text "Work Tasks"
  end

  test "editing a list" do
    list = @user.todo_lists.create!(name: "Old Name", color: "purple", template: "blank")
    visit edit_todo_list_path(list)

    assert_text "Edit list"
    set_wa_input_by_id("todo_list_name", "New Name")
    click_wa_button("Save Changes")

    assert_text "List updated successfully", wait: 5
    assert_text "New Name"
  end

  test "deleting a list" do
    list = @user.todo_lists.create!(name: "To Delete", color: "pink", template: "blank")
    visit todo_list_path(list)

    click_button "Delete"
    within "wa-dialog" do
      click_button "Delete"
    end

    assert_text "List deleted successfully", wait: 5
    assert_no_text "To Delete"
  end

  test "validation errors on create" do
    @user.todo_lists.create!(name: "Existing", color: "purple", template: "blank")
    visit new_todo_list_path

    set_wa_input_by_id("todo_list_name", "Existing")
    click_wa_button("Create List")

    assert_text "has already been taken", wait: 5
  end

  private

  # Set a wa-input value by its name attribute and dispatch wa-change
  def set_wa_input(name, value)
    page.execute_script <<~JS
      await customElements.whenDefined('wa-input');
      const input = document.querySelector('wa-input[name="#{name}"]');
      input.value = '#{value}';
      input.dispatchEvent(new Event('wa-change', { bubbles: true }));
    JS
  end

  # Set a wa-input value by its id attribute and dispatch wa-change
  def set_wa_input_by_id(id, value)
    page.execute_script <<~JS
      await customElements.whenDefined('wa-input');
      const input = document.querySelector('##{id}');
      input.value = '#{value}';
      input.dispatchEvent(new Event('wa-change', { bubbles: true }));
    JS
  end

  # Click a wa-button by its text content
  def click_wa_button(text)
    page.execute_script <<~JS
      const buttons = document.querySelectorAll('wa-button');
      for (const btn of buttons) {
        if (btn.textContent.trim().includes('#{text}')) {
          btn.click();
          break;
        }
      }
    JS
  end
end
