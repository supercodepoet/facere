require "test_helper"

class TodoListsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(
      name: "Test User",
      email_address: "controller_test@example.com",
      password: "Password1!",
      password_confirmation: "Password1!",
      terms_accepted_at: Time.current,
      email_verified_at: Time.current
    )
    @list = @user.todo_lists.create!(name: "Test List", color: "purple", template: "blank")
  end

  # sign_in_as is provided by SessionTestHelper

  # --- Authentication (all actions) ---

  test "requires authentication for index" do
    get todo_lists_url
    assert_response :redirect
  end

  test "requires authentication for show" do
    get todo_list_url(@list)
    assert_response :redirect
  end

  test "requires authentication for new" do
    get new_todo_list_url
    assert_response :redirect
  end

  test "requires authentication for create" do
    assert_no_difference("TodoList.count") do
      post todo_lists_url, params: { todo_list: { name: "Sneaky", color: "blue", template: "blank" } }
    end
    assert_response :redirect
  end

  test "requires authentication for edit" do
    get edit_todo_list_url(@list)
    assert_response :redirect
  end

  test "requires authentication for update" do
    patch todo_list_url(@list), params: { todo_list: { name: "Hacked" } }
    assert_response :redirect
    assert_equal "Test List", @list.reload.name
  end

  test "requires authentication for destroy" do
    assert_no_difference("TodoList.count") do
      delete todo_list_url(@list)
    end
    assert_response :redirect
  end

  # --- Index ---

  test "index shows blank slate when no lists" do
    sign_in_as(@user)
    @list.destroy!
    get todo_lists_url
    assert_response :success
    assert_match "Your lists are waiting", response.body
  end

  test "index shows list cards when lists exist" do
    sign_in_as(@user)
    get todo_lists_url
    assert_response :success
    assert_match "Test List", response.body
    assert_match "My Lists", response.body
  end

  test "index does not show other users lists" do
    sign_in_as(@user)
    other_user = User.create!(
      name: "Other",
      email_address: "other_index@example.com",
      password: "Password1!",
      password_confirmation: "Password1!",
      terms_accepted_at: Time.current,
      email_verified_at: Time.current
    )
    other_user.todo_lists.create!(name: "Secret List", color: "blue", template: "blank")
    get todo_lists_url
    assert_response :success
    assert_no_match "Secret List", response.body
  end

  test "index orders by most recently updated" do
    sign_in_as(@user)
    older = @user.todo_lists.create!(name: "Older", color: "blue", template: "blank")
    @list.touch
    get todo_lists_url
    assert_response :success
    assert response.body.index("Test List") < response.body.index("Older")
  end

  # --- Show ---

  test "show displays list details" do
    sign_in_as(@user)
    get todo_list_url(@list)
    assert_response :success
    assert_match "Test List", response.body
  end

  test "show displays blank slate for empty list" do
    sign_in_as(@user)
    get todo_list_url(@list)
    assert_response :success
    assert_match "Your list is ready", response.body
  end

  test "show displays sections and items for populated list" do
    sign_in_as(@user)
    project_list = @user.todo_lists.create!(name: "Project", color: "blue", template: "project")
    project_list.apply_template!
    get todo_list_url(project_list)
    assert_response :success
    assert_match "Planning", response.body
    assert_match "Define project scope", response.body
  end

  test "show returns not found for other users list" do
    sign_in_as(@user)
    other_user = User.create!(
      name: "Other",
      email_address: "other_ctrl@example.com",
      password: "Password1!",
      password_confirmation: "Password1!",
      terms_accepted_at: Time.current,
      email_verified_at: Time.current
    )
    other_list = other_user.todo_lists.create!(name: "Private", color: "blue", template: "blank")
    get todo_list_url(other_list)
    assert_response :not_found
  end

  # --- New / Create ---

  test "new renders create form" do
    sign_in_as(@user)
    get new_todo_list_url
    assert_response :success
    assert_match "Create a new list", response.body
  end

  test "create with valid params creates list and redirects" do
    sign_in_as(@user)
    assert_difference("TodoList.count", 1) do
      post todo_lists_url, params: { todo_list: { name: "New List", color: "blue", template: "blank" } }
    end
    assert_redirected_to todo_list_url(TodoList.last)
    follow_redirect!
    assert_match "List created successfully", response.body
  end

  test "create applies template on creation" do
    sign_in_as(@user)
    post todo_lists_url, params: { todo_list: { name: "My Project", color: "teal", template: "project" } }
    list = TodoList.find_by(name: "My Project")
    assert_equal 4, list.todo_sections.count
    assert list.todo_items.count > 0
  end

  test "create with missing name re-renders form with errors" do
    sign_in_as(@user)
    post todo_lists_url, params: { todo_list: { name: "", color: "purple", template: "blank" } }
    assert_response :unprocessable_entity
    assert_match "can&#39;t be blank", response.body
  end

  test "create with duplicate name re-renders form with errors" do
    sign_in_as(@user)
    post todo_lists_url, params: { todo_list: { name: "Test List", color: "purple", template: "blank" } }
    assert_response :unprocessable_entity
    assert_match "has already been taken", response.body
  end

  test "create with duplicate name case-insensitive" do
    sign_in_as(@user)
    post todo_lists_url, params: { todo_list: { name: "test list", color: "purple", template: "blank" } }
    assert_response :unprocessable_entity
  end

  test "create ignores user_id parameter injection" do
    sign_in_as(@user)
    other_user = User.create!(
      name: "Victim",
      email_address: "victim@example.com",
      password: "Password1!",
      password_confirmation: "Password1!",
      terms_accepted_at: Time.current,
      email_verified_at: Time.current
    )
    post todo_lists_url, params: { todo_list: { name: "Injected", color: "blue", template: "blank", user_id: other_user.id } }
    new_list = TodoList.find_by(name: "Injected")
    assert_equal @user.id, new_list.user_id
  end

  # --- Edit / Update ---

  test "edit renders form with current values" do
    sign_in_as(@user)
    get edit_todo_list_url(@list)
    assert_response :success
    assert_match "Edit list", response.body
    assert_match "Test List", response.body
  end

  test "edit returns not found for other users list" do
    sign_in_as(@user)
    other_user = User.create!(
      name: "Other",
      email_address: "other_edit@example.com",
      password: "Password1!",
      password_confirmation: "Password1!",
      terms_accepted_at: Time.current,
      email_verified_at: Time.current
    )
    other_list = other_user.todo_lists.create!(name: "Private", color: "blue", template: "blank")
    get edit_todo_list_url(other_list)
    assert_response :not_found
  end

  test "update with valid params updates and redirects" do
    sign_in_as(@user)
    patch todo_list_url(@list), params: { todo_list: { name: "Updated Name", color: "blue" } }
    assert_redirected_to todo_list_url(@list)
    assert_equal "Updated Name", @list.reload.name
  end

  test "update does not change template" do
    sign_in_as(@user)
    patch todo_list_url(@list), params: { todo_list: { name: "Same", template: "project" } }
    assert_equal "blank", @list.reload.template
  end

  test "update with duplicate name re-renders form" do
    sign_in_as(@user)
    @user.todo_lists.create!(name: "Other List", color: "blue", template: "blank")
    patch todo_list_url(@list), params: { todo_list: { name: "Other List" } }
    assert_response :unprocessable_entity
  end

  test "update with blank name re-renders form" do
    sign_in_as(@user)
    patch todo_list_url(@list), params: { todo_list: { name: "" } }
    assert_response :unprocessable_entity
  end

  test "update returns not found for other users list" do
    sign_in_as(@user)
    other_user = User.create!(
      name: "Other",
      email_address: "other_update@example.com",
      password: "Password1!",
      password_confirmation: "Password1!",
      terms_accepted_at: Time.current,
      email_verified_at: Time.current
    )
    other_list = other_user.todo_lists.create!(name: "Private", color: "blue", template: "blank")
    patch todo_list_url(other_list), params: { todo_list: { name: "Hacked" } }
    assert_response :not_found
    assert_equal "Private", other_list.reload.name
  end

  # --- Destroy ---

  test "destroy deletes list and redirects to index" do
    sign_in_as(@user)
    assert_difference("TodoList.count", -1) do
      delete todo_list_url(@list)
    end
    assert_redirected_to todo_lists_url
    follow_redirect!
    assert_match "List deleted successfully", response.body
  end

  test "destroy cascades to sections and items" do
    sign_in_as(@user)
    project_list = @user.todo_lists.create!(name: "To Delete", color: "teal", template: "project")
    project_list.apply_template!
    section_ids = project_list.todo_section_ids

    delete todo_list_url(project_list)
    assert_equal 0, TodoSection.where(id: section_ids).count
  end

  test "destroy scopes to current user" do
    sign_in_as(@user)
    other_user = User.create!(
      name: "Other",
      email_address: "other_del@example.com",
      password: "Password1!",
      password_confirmation: "Password1!",
      terms_accepted_at: Time.current,
      email_verified_at: Time.current
    )
    other_list = other_user.todo_lists.create!(name: "Private", color: "blue", template: "blank")
    delete todo_list_url(other_list)
    assert_response :not_found
  end
end
