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

    visit sign_in_path
    fill_in "email_address", with: "system@example.com"
    fill_in "password", with: "Password1!"
    find("button.auth-primary-btn").click
    assert_no_text "Welcome back!", wait: 10
  end

  test "viewing blank slate when no lists" do
    assert_text "Your lists are waiting!"
    assert_link "Create My First List"
  end

  test "creating a new list with blank template" do
    click_link "Create My First List"
    assert_text "Create a new list"

    fill_in "todo_list[name]", with: "My First List"
    find("button[type='submit']", text: "Create List").click

    assert_text "List created successfully", wait: 5
    assert_text "My First List"
    assert_text "Your list is ready"
  end

  test "creating a list with project template" do
    click_link "Create My First List"
    assert_text "Create a new list"

    fill_in "todo_list[name]", with: "Project Plan"
    page.execute_script <<~JS
      document.querySelector('input[name="todo_list[template]"]').value = 'project';
    JS
    find("button[type='submit']", text: "Create List").click

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
    fill_in "todo_list[name]", with: "New Name"
    find("button[type='submit']", text: "Save Changes").click

    assert_text "List updated successfully", wait: 5
    assert_text "New Name"
  end

  test "deleting a list" do
    list = @user.todo_lists.create!(name: "To Delete", color: "pink", template: "blank")
    visit todo_list_path(list)

    find("button.show-action-btn-danger", wait: 5).click

    within ".delete-modal-overlay" do
      find("button.delete-confirm-btn", wait: 5).click
    end

    assert_text "List deleted successfully", wait: 5
    assert_no_text "To Delete"
  end

  test "validation errors on create" do
    @user.todo_lists.create!(name: "Existing", color: "purple", template: "blank")
    visit new_todo_list_path

    fill_in "todo_list[name]", with: "Existing"
    find("button[type='submit']", text: "Create List").click

    assert_text "has already been taken", wait: 5
  end
end
