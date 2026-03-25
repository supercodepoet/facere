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

  # ── Index ─────────────────────────────────────────────

  test "index requires authentication" do
    get todo_list_todo_item_tags_url(@list, @item)
    assert_response :redirect
  end

  test "index on other user list returns 404" do
    sign_in_as(@user)
    get todo_list_todo_item_tags_url(@other_list, @other_item)
    assert_response :not_found
  end

  test "index returns tag list with applied tag ids" do
    tag1 = @user.tags.create!(name: "Design", color: "#8B5CF6")
    tag2 = @user.tags.create!(name: "Urgent", color: "#EF4444")
    @item.item_tags.create!(tag: tag1)
    sign_in_as(@user)
    get todo_list_todo_item_tags_url(@list, @item)
    assert_response :success
    assert_includes response.body, "Design"
    assert_includes response.body, "Urgent"
  end

  # ── Create (new tag) ──────────────────────────────────

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

  test "create with turbo stream responds with turbo stream" do
    sign_in_as(@user)
    post todo_list_todo_item_tags_url(@list, @item),
      params: { tag: { name: "NewTag", color: "#14B8A6" } },
      headers: { "Accept" => "text/vnd.turbo-stream.html" }
    assert_response :success
    assert_includes response.media_type, "turbo-stream"
  end

  # ── Create (toggle existing tag on) ──────────────────

  test "toggle existing tag onto item" do
    tag = @user.tags.create!(name: "Design", color: "#8B5CF6")
    sign_in_as(@user)
    assert_difference("ItemTag.count", 1) do
      post todo_list_todo_item_tags_url(@list, @item), params: { tag: { id: tag.id } }
    end
    assert_includes @item.reload.tag_ids, tag.id
  end

  test "toggle existing tag is idempotent" do
    tag = @user.tags.create!(name: "Design", color: "#8B5CF6")
    @item.item_tags.create!(tag: tag)
    sign_in_as(@user)
    assert_no_difference("ItemTag.count") do
      post todo_list_todo_item_tags_url(@list, @item), params: { tag: { id: tag.id } }
    end
  end

  test "cannot toggle another user tag onto item" do
    other_tag = @other_user.tags.create!(name: "Hacked", color: "#FF0000")
    sign_in_as(@user)
    post todo_list_todo_item_tags_url(@list, @item), params: { tag: { id: other_tag.id } }
    assert_response :not_found
  end

  # ── Update ────────────────────────────────────────────

  test "update requires authentication" do
    tag = @user.tags.create!(name: "Design", color: "#8B5CF6")
    patch todo_list_todo_item_tag_url(@list, @item, tag), params: { tag: { name: "Updated" } }
    assert_response :redirect
    assert_equal "Design", tag.reload.name
  end

  test "update changes tag name" do
    tag = @user.tags.create!(name: "Design", color: "#8B5CF6")
    @item.item_tags.create!(tag: tag)
    sign_in_as(@user)
    patch todo_list_todo_item_tag_url(@list, @item, tag), params: { tag: { name: "UI Design" } }
    assert_equal "UI Design", tag.reload.name
  end

  test "update changes tag color" do
    tag = @user.tags.create!(name: "Design", color: "#8B5CF6")
    @item.item_tags.create!(tag: tag)
    sign_in_as(@user)
    patch todo_list_todo_item_tag_url(@list, @item, tag), params: { tag: { color: "#EF4444" } }
    assert_equal "#EF4444", tag.reload.color
  end

  test "update rejects duplicate name" do
    @user.tags.create!(name: "Existing", color: "#EF4444")
    tag = @user.tags.create!(name: "Design", color: "#8B5CF6")
    @item.item_tags.create!(tag: tag)
    sign_in_as(@user)
    patch todo_list_todo_item_tag_url(@list, @item, tag), params: { tag: { name: "Existing" } }
    assert_equal "Design", tag.reload.name
  end

  test "update other user tag returns 404" do
    other_tag = @other_user.tags.create!(name: "Other", color: "#FF0000")
    sign_in_as(@user)
    patch todo_list_todo_item_tag_url(@list, @item, other_tag), params: { tag: { name: "Hacked" } }
    assert_response :not_found
  end

  test "update with turbo stream responds with turbo stream" do
    tag = @user.tags.create!(name: "Design", color: "#8B5CF6")
    @item.item_tags.create!(tag: tag)
    sign_in_as(@user)
    patch todo_list_todo_item_tag_url(@list, @item, tag),
      params: { tag: { name: "Updated" } },
      headers: { "Accept" => "text/vnd.turbo-stream.html" }
    assert_response :success
    assert_includes response.media_type, "turbo-stream"
  end

  # ── Destroy (remove from item) ──────────────────────

  test "destroy removes tag from item" do
    tag = @user.tags.create!(name: "Design", color: "#8B5CF6")
    @item.item_tags.create!(tag: tag)
    sign_in_as(@user)
    assert_difference("ItemTag.count", -1) do
      delete todo_list_todo_item_tag_url(@list, @item, tag)
    end
    assert_not_includes @item.reload.tags.pluck(:name), "Design"
    assert Tag.exists?(tag.id), "Tag itself should not be deleted"
  end

  # ── Destroy (permanent) ─────────────────────────────

  test "permanent destroy deletes tag entirely" do
    tag = @user.tags.create!(name: "Design", color: "#8B5CF6")
    @item.item_tags.create!(tag: tag)
    sign_in_as(@user)
    assert_difference([ "Tag.count", "ItemTag.count" ], -1) do
      delete todo_list_todo_item_tag_url(@list, @item, tag), params: { permanent: "true" }
    end
    assert_not Tag.exists?(tag.id)
  end

  test "permanent destroy removes tag from all items" do
    tag = @user.tags.create!(name: "Design", color: "#8B5CF6")
    item2 = @list.todo_items.create!(name: "Item 2", position: 1, status: "todo", priority: "none")
    @item.item_tags.create!(tag: tag)
    item2.item_tags.create!(tag: tag)
    sign_in_as(@user)
    assert_difference("ItemTag.count", -2) do
      delete todo_list_todo_item_tag_url(@list, @item, tag), params: { permanent: "true" }
    end
  end

  test "permanent destroy other user tag returns 404" do
    other_tag = @other_user.tags.create!(name: "Other", color: "#FF0000")
    sign_in_as(@user)
    delete todo_list_todo_item_tag_url(@list, @item, other_tag), params: { permanent: "true" }
    assert_response :not_found
  end

  test "destroy with turbo stream responds with turbo stream" do
    tag = @user.tags.create!(name: "Design", color: "#8B5CF6")
    @item.item_tags.create!(tag: tag)
    sign_in_as(@user)
    delete todo_list_todo_item_tag_url(@list, @item, tag),
      headers: { "Accept" => "text/vnd.turbo-stream.html" }
    assert_response :success
    assert_includes response.media_type, "turbo-stream"
  end

  # ── Parameter injection ─────────────────────────────

  test "create cannot override user_id" do
    sign_in_as(@user)
    post todo_list_todo_item_tags_url(@list, @item),
      params: { tag: { name: "Injected", color: "#FF0000", user_id: @other_user.id } }
    tag = Tag.find_by(name: "Injected")
    assert_equal @user.id, tag.user_id if tag
  end
end
