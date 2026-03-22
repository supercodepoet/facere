require "test_helper"

class TodoItemsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(
      name: "Test User",
      email_address: "items_ctrl@example.com",
      password: "Password1!",
      password_confirmation: "Password1!",
      terms_accepted_at: Time.current,
      email_verified_at: Time.current
    )
    @todo_list = @user.todo_lists.create!(name: "Test List", color: "purple", template: "blank")
    @todo_item = @todo_list.todo_items.create!(name: "Buy milk", position: 0, status: "todo", priority: "none")

    @other_user = User.create!(
      name: "Other User",
      email_address: "other_items@example.com",
      password: "Password1!",
      password_confirmation: "Password1!",
      terms_accepted_at: Time.current,
      email_verified_at: Time.current
    )
    @other_list = @other_user.todo_lists.create!(name: "Other List", color: "blue", template: "blank")
    @other_item = @other_list.todo_items.create!(name: "Other item", position: 0, status: "todo", priority: "none")
  end

  # --- Authentication (all actions) ---

  test "show requires authentication" do
    get todo_list_todo_item_url(@todo_list, @todo_item)
    assert_response :redirect
  end

  test "create requires authentication" do
    assert_no_difference("TodoItem.count") do
      post todo_list_todo_items_url(@todo_list), params: { todo_item: { name: "Sneaky", status: "todo", priority: "none" } }
    end
    assert_response :redirect
  end

  test "update requires authentication" do
    patch todo_list_todo_item_url(@todo_list, @todo_item), params: { todo_item: { name: "Hacked" } }
    assert_response :redirect
    assert_equal "Buy milk", @todo_item.reload.name
  end

  test "destroy requires authentication" do
    assert_no_difference("TodoItem.count") do
      delete todo_list_todo_item_url(@todo_list, @todo_item)
    end
    assert_response :redirect
  end

  test "toggle requires authentication" do
    patch toggle_todo_list_todo_item_url(@todo_list, @todo_item)
    assert_response :redirect
    assert_equal false, @todo_item.reload.completed
  end

  test "archive requires authentication" do
    patch archive_todo_list_todo_item_url(@todo_list, @todo_item)
    assert_response :redirect
    assert_equal false, @todo_item.reload.archived
  end

  test "move requires authentication" do
    patch move_todo_list_todo_item_url(@todo_list, @todo_item), params: { target_position: 1 }
    assert_response :redirect
  end

  test "copy requires authentication" do
    assert_no_difference("TodoItem.count") do
      post copy_todo_list_todo_item_url(@todo_list, @todo_item), params: { target_position: 1 }
    end
    assert_response :redirect
  end

  test "reorder requires authentication" do
    patch reorder_todo_list_todo_items_url(@todo_list), params: { items: [ { id: @todo_item.id, position: 0 } ] }
    assert_response :redirect
  end

  # --- Authorization (other user's items return 404) ---

  test "show other user item returns 404" do
    sign_in_as(@user)
    get todo_list_todo_item_url(@other_list, @other_item)
    assert_response :not_found
  end

  test "update other user item returns 404" do
    sign_in_as(@user)
    patch todo_list_todo_item_url(@other_list, @other_item), params: { todo_item: { name: "Hacked" } }
    assert_response :not_found
    assert_equal "Other item", @other_item.reload.name
  end

  test "destroy other user item returns 404" do
    sign_in_as(@user)
    assert_no_difference("TodoItem.count") do
      delete todo_list_todo_item_url(@other_list, @other_item)
    end
    assert_response :not_found
  end

  test "toggle other user item returns 404" do
    sign_in_as(@user)
    patch toggle_todo_list_todo_item_url(@other_list, @other_item)
    assert_response :not_found
    assert_equal false, @other_item.reload.completed
  end

  # --- Toggle tests ---

  test "toggle changes completed state" do
    sign_in_as(@user)
    assert_equal false, @todo_item.completed

    patch toggle_todo_list_todo_item_url(@todo_list, @todo_item)
    assert_response :redirect
    assert @todo_item.reload.completed
  end

  test "toggle syncs status to done when completed" do
    sign_in_as(@user)
    patch toggle_todo_list_todo_item_url(@todo_list, @todo_item), as: :turbo_stream

    @todo_item.reload
    assert @todo_item.completed
    assert_equal "done", @todo_item.status
  end

  # --- Parameter injection ---

  # --- Status update tests (US1) ---

  test "update status to in_progress" do
    sign_in_as(@user)
    patch todo_list_todo_item_url(@todo_list, @todo_item), params: { todo_item: { status: "in_progress" } }
    assert_response :redirect
    assert_equal "in_progress", @todo_item.reload.status
    assert_not @todo_item.completed
  end

  test "update status to on_hold" do
    sign_in_as(@user)
    patch todo_list_todo_item_url(@todo_list, @todo_item), params: { todo_item: { status: "on_hold" } }
    assert_response :redirect
    assert_equal "on_hold", @todo_item.reload.status
    assert_not @todo_item.completed
  end

  test "update status to done marks completed" do
    sign_in_as(@user)
    patch todo_list_todo_item_url(@todo_list, @todo_item), params: { todo_item: { status: "done" } }
    assert_response :redirect
    @todo_item.reload
    assert_equal "done", @todo_item.status
    assert @todo_item.completed
  end

  test "update status away from done unmarks completed" do
    @todo_item.update!(status: "done", completed: true)
    sign_in_as(@user)
    patch todo_list_todo_item_url(@todo_list, @todo_item), params: { todo_item: { status: "todo" } }
    assert_response :redirect
    @todo_item.reload
    assert_equal "todo", @todo_item.status
    assert_not @todo_item.completed
  end

  # --- Priority update tests (US1) ---

  test "update priority to urgent" do
    sign_in_as(@user)
    patch todo_list_todo_item_url(@todo_list, @todo_item), params: { todo_item: { priority: "urgent" } }
    assert_response :redirect
    assert_equal "urgent", @todo_item.reload.priority
  end

  test "update priority to high" do
    sign_in_as(@user)
    patch todo_list_todo_item_url(@todo_list, @todo_item), params: { todo_item: { priority: "high" } }
    assert_response :redirect
    assert_equal "high", @todo_item.reload.priority
  end

  test "update priority to normal" do
    sign_in_as(@user)
    patch todo_list_todo_item_url(@todo_list, @todo_item), params: { todo_item: { priority: "normal" } }
    assert_response :redirect
    assert_equal "normal", @todo_item.reload.priority
  end

  test "update priority to low" do
    sign_in_as(@user)
    patch todo_list_todo_item_url(@todo_list, @todo_item), params: { todo_item: { priority: "low" } }
    assert_response :redirect
    assert_equal "low", @todo_item.reload.priority
  end

  test "update priority to none" do
    @todo_item.update!(priority: "high")
    sign_in_as(@user)
    patch todo_list_todo_item_url(@todo_list, @todo_item), params: { todo_item: { priority: "none" } }
    assert_response :redirect
    assert_equal "none", @todo_item.reload.priority
  end

  # --- Notes auto-save tests (US2) ---

  test "update notes via patch" do
    sign_in_as(@user)
    patch todo_list_todo_item_url(@todo_list, @todo_item), params: { todo_item: { notes: "<p>Updated notes content</p>" } }
    assert_response :redirect
    @todo_item.reload
    assert_includes @todo_item.notes.to_s, "Updated notes content"
  end

  test "update notes preserves other fields" do
    @todo_item.update!(status: "in_progress", priority: "high")
    sign_in_as(@user)
    patch todo_list_todo_item_url(@todo_list, @todo_item), params: { todo_item: { notes: "<p>Notes only</p>" } }
    assert_response :redirect
    @todo_item.reload
    assert_equal "in_progress", @todo_item.status
    assert_equal "high", @todo_item.priority
  end

  test "create ignores todo_list_id injection" do
    sign_in_as(@user)
    assert_difference("TodoItem.count", 1) do
      post todo_list_todo_items_url(@todo_list), params: { todo_item: { name: "Injected", status: "todo", priority: "none", todo_list_id: @other_list.id } }, as: :turbo_stream
    end

    new_item = TodoItem.find_by(name: "Injected")
    assert_not_nil new_item
    assert_equal @todo_list.id, new_item.todo_list_id
  end
end
