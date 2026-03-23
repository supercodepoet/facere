require "test_helper"

class CollaborationAuthorizationTest < ActionDispatch::IntegrationTest
  setup do
    @owner = User.create!(
      name: "Owner",
      email_address: "collab_auth_owner@example.com",
      password: "Password1!",
      password_confirmation: "Password1!",
      terms_accepted_at: Time.current,
      email_verified_at: Time.current
    )
    @editor = User.create!(
      name: "Editor",
      email_address: "collab_auth_editor@example.com",
      password: "Password1!",
      password_confirmation: "Password1!",
      terms_accepted_at: Time.current,
      email_verified_at: Time.current
    )
    @viewer = User.create!(
      name: "Viewer",
      email_address: "collab_auth_viewer@example.com",
      password: "Password1!",
      password_confirmation: "Password1!",
      terms_accepted_at: Time.current,
      email_verified_at: Time.current
    )
    @outsider = User.create!(
      name: "Outsider",
      email_address: "collab_auth_outsider@example.com",
      password: "Password1!",
      password_confirmation: "Password1!",
      terms_accepted_at: Time.current,
      email_verified_at: Time.current
    )
    @list = @owner.todo_lists.create!(name: "Shared List", color: "purple", template: "blank")
    @section = @list.all_todo_sections.create!(name: "Test Section", position: 0)
    @item = @list.todo_items.create!(name: "Test Item", position: 0, status: "todo", priority: "none")
    @list.list_collaborators.create!(user: @editor, role: "editor")
    @list.list_collaborators.create!(user: @viewer, role: "viewer")
  end

  # --- TodoListsController ---

  test "editor can view shared list" do
    sign_in_as(@editor)
    get todo_list_url(@list)
    assert_response :success
  end

  test "viewer can view shared list" do
    sign_in_as(@viewer)
    get todo_list_url(@list)
    assert_response :success
  end

  test "outsider cannot view shared list" do
    sign_in_as(@outsider)
    get todo_list_url(@list)
    assert_response :not_found
  end

  test "editor cannot edit list settings" do
    sign_in_as(@editor)
    get edit_todo_list_url(@list)
    assert_response :not_found
  end

  test "editor cannot delete list" do
    sign_in_as(@editor)
    assert_no_difference("TodoList.count") do
      delete todo_list_url(@list)
    end
    assert_response :not_found
  end

  test "shared lists appear in index" do
    sign_in_as(@editor)
    get todo_lists_url
    assert_response :success
    assert_match "Shared List", response.body
  end

  # --- TodoItemsController ---

  test "editor can view item on shared list" do
    sign_in_as(@editor)
    get todo_list_todo_item_url(@list, @item)
    assert_response :success
  end

  test "viewer can view item on shared list" do
    sign_in_as(@viewer)
    get todo_list_todo_item_url(@list, @item)
    assert_response :success
  end

  test "editor can create item on shared list" do
    sign_in_as(@editor)
    assert_difference("TodoItem.count", 1) do
      post todo_list_todo_items_url(@list), params: { todo_item: { name: "New Item" } }
    end
  end

  test "viewer cannot create item on shared list" do
    sign_in_as(@viewer)
    assert_no_difference("TodoItem.count") do
      post todo_list_todo_items_url(@list), params: { todo_item: { name: "New Item" } }
    end
    assert_response :not_found
  end

  test "editor can toggle item on shared list" do
    sign_in_as(@editor)
    patch toggle_todo_list_todo_item_url(@list, @item)
    assert_response :redirect
    assert @item.reload.completed?
  end

  test "viewer cannot toggle item on shared list" do
    sign_in_as(@viewer)
    patch toggle_todo_list_todo_item_url(@list, @item)
    assert_response :not_found
    assert_not @item.reload.completed?
  end

  test "editor can update item on shared list" do
    sign_in_as(@editor)
    patch todo_list_todo_item_url(@list, @item), params: { todo_item: { status: "in_progress" } }
    assert_not_equal :not_found, response.status
    assert_equal "in_progress", @item.reload.status
  end

  test "viewer cannot update item on shared list" do
    sign_in_as(@viewer)
    patch todo_list_todo_item_url(@list, @item), params: { todo_item: { status: "in_progress" } }
    assert_response :not_found
    assert_equal "todo", @item.reload.status
  end

  test "editor can delete item on shared list" do
    sign_in_as(@editor)
    assert_difference("TodoItem.count", -1) do
      delete todo_list_todo_item_url(@list, @item)
    end
  end

  test "viewer cannot delete item on shared list" do
    sign_in_as(@viewer)
    assert_no_difference("TodoItem.count") do
      delete todo_list_todo_item_url(@list, @item)
    end
    assert_response :not_found
  end

  # --- TodoSectionsController ---

  test "editor can create section on shared list" do
    sign_in_as(@editor)
    assert_difference("TodoSection.count", 1) do
      post todo_list_todo_sections_url(@list), params: { todo_section: { name: "New Section" } }
    end
  end

  test "viewer cannot create section on shared list" do
    sign_in_as(@viewer)
    assert_no_difference("TodoSection.count") do
      post todo_list_todo_sections_url(@list), params: { todo_section: { name: "New Section" } }
    end
    assert_response :not_found
  end

  # --- CommentsController ---

  test "viewer can comment on shared list item" do
    sign_in_as(@viewer)
    assert_difference("Comment.count", 1) do
      post todo_list_todo_item_comments_url(@list, @item), params: { comment: { body: "Viewer comment" } }
    end
  end

  test "editor can comment on shared list item" do
    sign_in_as(@editor)
    assert_difference("Comment.count", 1) do
      post todo_list_todo_item_comments_url(@list, @item), params: { comment: { body: "Editor comment" } }
    end
  end

  test "outsider cannot comment on shared list item" do
    sign_in_as(@outsider)
    assert_no_difference("Comment.count") do
      post todo_list_todo_item_comments_url(@list, @item), params: { comment: { body: "Outsider comment" } }
    end
    assert_response :not_found
  end

  # --- ChecklistItemsController ---

  test "viewer cannot create checklist item" do
    sign_in_as(@viewer)
    assert_no_difference("ChecklistItem.count") do
      post todo_list_todo_item_checklist_items_url(@list, @item), params: { checklist_item: { name: "Sub task" } }
    end
    assert_response :not_found
  end

  # --- TagsController ---

  test "viewer cannot add tag" do
    sign_in_as(@viewer)
    assert_no_difference("Tag.count") do
      post todo_list_todo_item_tags_url(@list, @item), params: { tag: { name: "urgent" } }
    end
    assert_response :not_found
  end
end
