require "test_helper"

class ItemAssigneesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @owner = User.create!(
      name: "Owner",
      email_address: "assign_owner@example.com",
      password: "Password1!",
      password_confirmation: "Password1!",
      terms_accepted_at: Time.current,
      email_verified_at: Time.current
    )
    @editor = User.create!(
      name: "Editor",
      email_address: "assign_editor@example.com",
      password: "Password1!",
      password_confirmation: "Password1!",
      terms_accepted_at: Time.current,
      email_verified_at: Time.current
    )
    @viewer = User.create!(
      name: "Viewer",
      email_address: "assign_viewer@example.com",
      password: "Password1!",
      password_confirmation: "Password1!",
      terms_accepted_at: Time.current,
      email_verified_at: Time.current
    )
    @outsider = User.create!(
      name: "Outsider",
      email_address: "assign_outsider@example.com",
      password: "Password1!",
      password_confirmation: "Password1!",
      terms_accepted_at: Time.current,
      email_verified_at: Time.current
    )
    @list = @owner.todo_lists.create!(name: "Shared List", color: "purple", template: "blank")
    @item = @list.todo_items.create!(name: "Test Item", position: 0, status: "todo", priority: "none")
    @list.list_collaborators.create!(user: @editor, role: "editor")
    @list.list_collaborators.create!(user: @viewer, role: "viewer")
  end

  # --- Authentication ---

  test "create requires authentication" do
    assert_no_difference("ItemAssignee.count") do
      post todo_list_todo_item_item_assignees_url(@list, @item), params: { user_id: @editor.id }
    end
    assert_response :redirect
  end

  # --- Authorization ---

  test "create requires editor role, viewer gets 404" do
    sign_in_as(@viewer)
    assert_no_difference("ItemAssignee.count") do
      post todo_list_todo_item_item_assignees_url(@list, @item), params: { user_id: @editor.id }
    end
    assert_response :not_found
  end

  # --- Create ---

  test "create assigns a list member to item" do
    sign_in_as(@editor)
    assert_difference("ItemAssignee.count", 1) do
      post todo_list_todo_item_item_assignees_url(@list, @item), params: { user_id: @viewer.id }
    end
    assert_response :redirect
    assert @item.item_assignees.exists?(user: @viewer)
  end

  test "create rejects non-list-member and returns 404" do
    sign_in_as(@editor)
    assert_no_difference("ItemAssignee.count") do
      post todo_list_todo_item_item_assignees_url(@list, @item), params: { user_id: @outsider.id }
    end
    assert_response :not_found
  end

  test "create duplicate assignment fails gracefully" do
    sign_in_as(@editor)
    @item.item_assignees.create!(user: @viewer)

    assert_no_difference("ItemAssignee.count") do
      post todo_list_todo_item_item_assignees_url(@list, @item), params: { user_id: @viewer.id }
    end
    assert_response :redirect
  end

  # --- Destroy ---

  test "destroy removes assignment" do
    sign_in_as(@editor)
    assignee = @item.item_assignees.create!(user: @viewer)

    assert_difference("ItemAssignee.count", -1) do
      delete todo_list_todo_item_item_assignee_url(@list, @item, assignee)
    end
    assert_response :redirect
  end

  test "destroy requires editor role" do
    sign_in_as(@viewer)
    assignee = @item.item_assignees.create!(user: @viewer)

    assert_no_difference("ItemAssignee.count") do
      delete todo_list_todo_item_item_assignee_url(@list, @item, assignee)
    end
    assert_response :not_found
  end
end
