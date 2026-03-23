require "test_helper"

class CommentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(
      name: "Comment Test",
      email_address: "comment_ctrl@example.com",
      password: "Password1!",
      password_confirmation: "Password1!",
      terms_accepted_at: Time.current,
      email_verified_at: Time.current
    )
    @list = @user.todo_lists.create!(name: "Test List", color: "purple", template: "blank")
    @item = @list.todo_items.create!(name: "Test Item", position: 0, status: "todo", priority: "none")
    @comment = @item.comments.create!(body: "First comment", user: @user)

    @other_user = User.create!(
      name: "Other User",
      email_address: "other_comment@example.com",
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
    assert_no_difference("Comment.count") do
      post todo_list_todo_item_comments_url(@list, @item), params: { comment: { body: "Sneaky" } }
    end
    assert_response :redirect
  end

  # --- Authorization ---

  test "create on other user item returns 404" do
    sign_in_as(@user)
    assert_no_difference("Comment.count") do
      post todo_list_todo_item_comments_url(@other_list, @other_item), params: { comment: { body: "Hacked" } }
    end
    assert_response :not_found
  end

  # --- Create ---

  test "create with valid body" do
    sign_in_as(@user)
    assert_difference("Comment.count", 1) do
      post todo_list_todo_item_comments_url(@list, @item), params: { comment: { body: "New comment" } }
    end
    assert_response :redirect
    assert_equal @user.id, Comment.last.user_id
  end

  test "create with empty body fails" do
    sign_in_as(@user)
    assert_no_difference("Comment.count") do
      post todo_list_todo_item_comments_url(@list, @item), params: { comment: { body: "" } }
    end
    assert_response :redirect
  end

  test "create with whitespace-only body fails" do
    sign_in_as(@user)
    assert_no_difference("Comment.count") do
      post todo_list_todo_item_comments_url(@list, @item), params: { comment: { body: "   " } }
    end
    assert_response :redirect
  end

  test "create reply with parent_id" do
    sign_in_as(@user)
    assert_difference("Comment.count", 1) do
      post todo_list_todo_item_comments_url(@list, @item), params: { comment: { body: "Reply", parent_id: @comment.id } }
    end
    assert_response :redirect
    reply = Comment.last
    assert_equal @comment.id, reply.parent_id
  end

  # --- Update ---

  test "update own comment sets edited_at" do
    sign_in_as(@user)
    patch todo_list_todo_item_comment_url(@list, @item, @comment), params: { comment: { body: "Updated" } }
    assert_response :redirect
    @comment.reload
    assert_equal "Updated", @comment.body
    assert_not_nil @comment.edited_at
  end

  test "update other user comment returns 404" do
    other_comment = @item.comments.create!(body: "Other's comment", user: @other_user)
    sign_in_as(@user)
    patch todo_list_todo_item_comment_url(@list, @item, other_comment), params: { comment: { body: "Hacked" } }
    assert_response :not_found
    assert_equal "Other's comment", other_comment.reload.body
  end

  # --- Destroy ---

  test "destroy own comment" do
    sign_in_as(@user)
    assert_difference("Comment.count", -1) do
      delete todo_list_todo_item_comment_url(@list, @item, @comment)
    end
    assert_response :redirect
  end

  test "destroy own comment cascades replies" do
    @item.comments.create!(body: "Reply", user: @user, parent_id: @comment.id)
    sign_in_as(@user)
    assert_difference("Comment.count", -2) do
      delete todo_list_todo_item_comment_url(@list, @item, @comment)
    end
    assert_response :redirect
  end

  test "destroy other user comment returns 404" do
    other_comment = @item.comments.create!(body: "Other's", user: @other_user)
    sign_in_as(@user)
    assert_no_difference("Comment.count") do
      delete todo_list_todo_item_comment_url(@list, @item, other_comment)
    end
    assert_response :not_found
  end
end
