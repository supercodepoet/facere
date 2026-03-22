require "test_helper"

class CommentLikesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(
      name: "Like Test",
      email_address: "like_ctrl@example.com",
      password: "Password1!",
      password_confirmation: "Password1!",
      terms_accepted_at: Time.current,
      email_verified_at: Time.current
    )
    @list = @user.todo_lists.create!(name: "Test List", color: "purple", template: "blank")
    @item = @list.todo_items.create!(name: "Test Item", position: 0, status: "todo", priority: "none")
    @comment = @item.comments.create!(body: "A comment", user: @user)
  end

  test "create requires authentication" do
    assert_no_difference("CommentLike.count") do
      post todo_list_todo_item_comment_likes_url(@list, @item, @comment)
    end
    assert_response :redirect
  end

  test "create adds like" do
    sign_in_as(@user)
    assert_difference("CommentLike.count", 1) do
      post todo_list_todo_item_comment_likes_url(@list, @item, @comment)
    end
    assert_response :redirect
    assert @comment.reload.liked_by?(@user)
  end

  test "create duplicate like fails gracefully" do
    CommentLike.create!(comment: @comment, user: @user)
    sign_in_as(@user)
    assert_no_difference("CommentLike.count") do
      post todo_list_todo_item_comment_likes_url(@list, @item, @comment)
    end
    assert_response :redirect
  end

  test "destroy removes like" do
    like = CommentLike.create!(comment: @comment, user: @user)
    sign_in_as(@user)
    assert_difference("CommentLike.count", -1) do
      delete todo_list_todo_item_comment_like_url(@list, @item, @comment, like)
    end
    assert_response :redirect
    assert_not @comment.reload.liked_by?(@user)
  end

  test "like increments counter cache" do
    sign_in_as(@user)
    post todo_list_todo_item_comment_likes_url(@list, @item, @comment)
    assert_equal 1, @comment.reload.likes_count
  end
end
