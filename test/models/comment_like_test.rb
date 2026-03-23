require "test_helper"

class CommentLikeTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(
      name: "Like Model Test",
      email_address: "like_model@example.com",
      password: "Password1!",
      password_confirmation: "Password1!",
      terms_accepted_at: Time.current
    )
    @list = @user.todo_lists.create!(name: "Test List", color: "purple", template: "blank")
    @item = @list.todo_items.create!(name: "Test Item", position: 0, status: "todo", priority: "none")
    @comment = @item.comments.create!(body: "Test comment", user: @user)
  end

  test "validates uniqueness of user per comment" do
    CommentLike.create!(comment: @comment, user: @user)
    duplicate = CommentLike.new(comment: @comment, user: @user)
    assert_not duplicate.valid?
    assert duplicate.errors[:user_id].any?
  end

  test "counter cache updates on create" do
    assert_equal 0, @comment.likes_count
    CommentLike.create!(comment: @comment, user: @user)
    assert_equal 1, @comment.reload.likes_count
  end

  test "counter cache updates on destroy" do
    like = CommentLike.create!(comment: @comment, user: @user)
    assert_equal 1, @comment.reload.likes_count
    like.destroy!
    assert_equal 0, @comment.reload.likes_count
  end
end
