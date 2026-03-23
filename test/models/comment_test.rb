require "test_helper"

class CommentTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(
      name: "Test User",
      email_address: "comment_test@example.com",
      password: "Password1!",
      password_confirmation: "Password1!",
      terms_accepted_at: Time.current
    )
    @list = @user.todo_lists.create!(name: "Test List", color: "purple", template: "blank")
    @item = @list.todo_items.create!(name: "Test Item", position: 0)
  end

  test "requires body presence" do
    comment = @item.comments.build(body: "", user: @user)
    assert_not comment.valid?
    assert_includes comment.errors[:body], "can't be blank"
  end

  test "enforces body maximum length of 2000" do
    comment = @item.comments.build(body: "a" * 2001, user: @user)
    assert_not comment.valid?
    assert comment.errors[:body].any? { |e| e.include?("too long") }
  end

  test "accepts body within maximum length" do
    comment = @item.comments.build(body: "a" * 2000, user: @user)
    assert comment.valid?
  end

  test "belongs to todo_item" do
    comment = @item.comments.create!(body: "A comment", user: @user)
    assert_equal @item, comment.todo_item
  end

  test "belongs to user" do
    comment = @item.comments.create!(body: "A comment", user: @user)
    assert_equal @user, comment.user
  end

  # --- Reply features (US5) ---

  test "top_level scope returns only root comments" do
    parent = @item.comments.create!(body: "Parent", user: @user)
    @item.comments.create!(body: "Reply", user: @user, parent: parent)
    assert_equal 1, @item.comments.top_level.count
  end

  test "nesting depth limit prevents deep nesting" do
    parent = @item.comments.create!(body: "Parent", user: @user)
    reply = @item.comments.create!(body: "Reply", user: @user, parent: parent)
    deep = @item.comments.build(body: "Deep reply", user: @user, parent: reply)
    assert_not deep.valid?
    assert deep.errors[:parent].any?
  end

  test "edited? returns true when edited_at is set" do
    comment = @item.comments.create!(body: "Original", user: @user)
    assert_not comment.edited?
    comment.update!(edited_at: Time.current)
    assert comment.edited?
  end

  test "liked_by? returns true when user has liked" do
    comment = @item.comments.create!(body: "Likeable", user: @user)
    assert_not comment.liked_by?(@user)
    CommentLike.create!(comment: comment, user: @user)
    assert comment.liked_by?(@user)
  end

  test "parent must belong to same todo_item" do
    other_item = @list.todo_items.create!(name: "Other Item", position: 1)
    other_comment = other_item.comments.create!(body: "Other", user: @user)
    reply = @item.comments.build(body: "Cross-item reply", user: @user, parent: other_comment)
    assert_not reply.valid?
    assert reply.errors[:parent].any?
  end

  test "destroying parent cascades to replies" do
    parent = @item.comments.create!(body: "Parent", user: @user)
    @item.comments.create!(body: "Reply 1", user: @user, parent: parent)
    @item.comments.create!(body: "Reply 2", user: @user, parent: parent)
    assert_difference("Comment.count", -3) do
      parent.destroy!
    end
  end
end
