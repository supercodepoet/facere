require "test_helper"

class TagsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(
      name: "Tag Test",
      email_address: "tag_ctrl@example.com",
      password: "Password1!",
      password_confirmation: "Password1!",
      terms_accepted_at: Time.current,
      email_verified_at: Time.current
    )
    @list = @user.todo_lists.create!(name: "Test List", color: "purple", template: "blank")
    @item = @list.todo_items.create!(name: "Test Item", position: 0, status: "todo", priority: "none")

    @other_user = User.create!(
      name: "Other User",
      email_address: "other_tag@example.com",
      password: "Password1!",
      password_confirmation: "Password1!",
      terms_accepted_at: Time.current,
      email_verified_at: Time.current
    )
    @other_list = @other_user.todo_lists.create!(name: "Other List", color: "blue", template: "blank")
    @other_item = @other_list.todo_items.create!(name: "Other Item", position: 0, status: "todo", priority: "none")
  end

  test "create requires authentication" do
    assert_no_difference("Tag.count") do
      post todo_list_todo_item_tags_url(@list, @item), params: { tag: { name: "Sneaky", color: "#FF0000" } }
    end
    assert_response :redirect
  end

  test "create on other user item returns 404" do
    sign_in_as(@user)
    post todo_list_todo_item_tags_url(@other_list, @other_item), params: { tag: { name: "Hacked", color: "#FF0000" } }
    assert_response :not_found
  end

  test "create adds tag to item" do
    sign_in_as(@user)
    assert_difference("ItemTag.count", 1) do
      post todo_list_todo_item_tags_url(@list, @item), params: { tag: { name: "Design", color: "#8B5CF6" } }
    end
    assert_response :redirect
    assert_includes @item.reload.tags.pluck(:name), "Design"
  end

  test "create reuses existing tag" do
    existing = @user.tags.create!(name: "Design", color: "#8B5CF6")
    sign_in_as(@user)
    assert_no_difference("Tag.count") do
      post todo_list_todo_item_tags_url(@list, @item), params: { tag: { name: "Design", color: "#8B5CF6" } }
    end
    assert_equal existing.id, @item.reload.tags.first.id
  end

  test "create prevents duplicate tag on same item" do
    tag = @user.tags.create!(name: "Design", color: "#8B5CF6")
    @item.item_tags.create!(tag: tag)
    sign_in_as(@user)
    assert_no_difference("ItemTag.count") do
      post todo_list_todo_item_tags_url(@list, @item), params: { tag: { name: "Design", color: "#8B5CF6" } }
    end
    assert_response :redirect
  end

  test "destroy removes tag from item" do
    tag = @user.tags.create!(name: "Design", color: "#8B5CF6")
    @item.item_tags.create!(tag: tag)
    sign_in_as(@user)
    assert_difference("ItemTag.count", -1) do
      delete todo_list_todo_item_tag_url(@list, @item, tag)
    end
    assert_response :redirect
    assert_not_includes @item.reload.tags.pluck(:name), "Design"
  end
end
