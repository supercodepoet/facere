require "test_helper"

class ChecklistItemsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(
      name: "Checklist Test",
      email_address: "checklist_ctrl@example.com",
      password: "Password1!",
      password_confirmation: "Password1!",
      terms_accepted_at: Time.current,
      email_verified_at: Time.current
    )
    @list = @user.todo_lists.create!(name: "Test List", color: "purple", template: "blank")
    @item = @list.todo_items.create!(name: "Test Item", position: 0, status: "todo", priority: "none")
    @checklist_item = @item.checklist_items.create!(name: "Sub-task 1", position: 0, completed: false)

    @other_user = User.create!(
      name: "Other User",
      email_address: "other_checklist@example.com",
      password: "Password1!",
      password_confirmation: "Password1!",
      terms_accepted_at: Time.current,
      email_verified_at: Time.current
    )
    @other_list = @other_user.todo_lists.create!(name: "Other List", color: "blue", template: "blank")
    @other_item = @other_list.todo_items.create!(name: "Other Item", position: 0, status: "todo", priority: "none")
  end

  # --- Authentication ---

  test "create requires authentication" do
    assert_no_difference("ChecklistItem.count") do
      post todo_list_todo_item_checklist_items_url(@list, @item), params: { checklist_item: { name: "Sneaky" } }
    end
    assert_response :redirect
  end

  test "toggle requires authentication" do
    patch toggle_todo_list_todo_item_checklist_item_url(@list, @item, @checklist_item)
    assert_response :redirect
    assert_not @checklist_item.reload.completed
  end

  test "destroy requires authentication" do
    assert_no_difference("ChecklistItem.count") do
      delete todo_list_todo_item_checklist_item_url(@list, @item, @checklist_item)
    end
    assert_response :redirect
  end

  # --- Authorization ---

  test "create on other user item returns 404" do
    sign_in_as(@user)
    assert_no_difference("ChecklistItem.count") do
      post todo_list_todo_item_checklist_items_url(@other_list, @other_item), params: { checklist_item: { name: "Hacked" } }
    end
    assert_response :not_found
  end

  # --- Create ---

  test "create with valid name" do
    sign_in_as(@user)
    assert_difference("ChecklistItem.count", 1) do
      post todo_list_todo_item_checklist_items_url(@list, @item), params: { checklist_item: { name: "New sub-task" } }
    end
    assert_response :redirect
    assert_equal "New sub-task", @item.checklist_items.last.name
  end

  test "create with empty name fails" do
    sign_in_as(@user)
    assert_no_difference("ChecklistItem.count") do
      post todo_list_todo_item_checklist_items_url(@list, @item), params: { checklist_item: { name: "" } }
    end
    assert_response :redirect
  end

  # --- Toggle ---

  test "toggle marks item complete" do
    sign_in_as(@user)
    assert_not_nil Current.session, "Session should be set"
    assert_not_nil Current.user, "User should be set"
    assert_equal @user.id, Current.user.id, "User should be the test user"
    assert_equal @list.id, Current.user.todo_lists.first.id, "List should belong to user"
    patch toggle_todo_list_todo_item_checklist_item_url(@list, @item, @checklist_item)
    assert_response :redirect, "Expected redirect but got #{response.status}."
    assert @checklist_item.reload.completed
  end

  test "toggle unmarks completed item" do
    @checklist_item.update!(completed: true)
    sign_in_as(@user)
    patch toggle_todo_list_todo_item_checklist_item_url(@list, @item, @checklist_item)
    assert_response :redirect
    assert_not @checklist_item.reload.completed
  end

  # --- Destroy ---

  test "destroy removes checklist item" do
    sign_in_as(@user)
    assert_difference("ChecklistItem.count", -1) do
      delete todo_list_todo_item_checklist_item_url(@list, @item, @checklist_item)
    end
    assert_response :redirect
  end
end
