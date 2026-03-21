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

    # Sign in
    visit sign_in_path
    fill_in "email_address", with: "system@example.com"
    fill_in "password", with: "Password1!"
    click_button "Sign in"
  end

  test "viewing blank slate when no lists" do
    assert_text "Your lists are waiting!"
    assert_link "Create My First List"
  end

  test "creating a new list with blank template" do
    click_link "Create My First List"
    assert_text "Create a new list"

    # Fill in wa-input via JavaScript since it's a web component
    page.execute_script("document.querySelector('#todo_list_name').value = 'My First List'")
    click_button "Create List"

    assert_text "List created successfully"
    assert_text "My First List"
    assert_text "Your list is ready"
  end

  test "creating a list with project template" do
    click_link "Create My First List"

    page.execute_script("document.querySelector('#todo_list_name').value = 'Project Plan'")
    # Select project template
    find("[data-template='project']").click
    click_button "Create List"

    assert_text "List created successfully"
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
    visit todo_list_path(list)
    click_link "Edit list"

    assert_text "Edit list"
    page.execute_script("document.querySelector('#todo_list_name').value = 'New Name'")
    click_button "Save Changes"

    assert_text "List updated successfully"
    assert_text "New Name"
  end

  test "deleting a list" do
    list = @user.todo_lists.create!(name: "To Delete", color: "pink", template: "blank")
    visit todo_list_path(list)

    click_button "Delete"
    within "wa-dialog" do
      click_button "Delete"
    end

    assert_text "List deleted successfully"
    assert_no_text "To Delete"
  end

  test "validation errors on create" do
    @user.todo_lists.create!(name: "Existing", color: "purple", template: "blank")
    visit new_todo_list_path

    page.execute_script("document.querySelector('#todo_list_name').value = 'Existing'")
    click_button "Create List"

    assert_text "has already been taken"
  end
end
