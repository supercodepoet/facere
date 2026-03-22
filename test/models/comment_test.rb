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
end
