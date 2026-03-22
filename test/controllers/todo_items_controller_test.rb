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
