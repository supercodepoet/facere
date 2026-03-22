require "test_helper"

class TagTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(
      name: "Test User",
      email_address: "tag_test@example.com",
      password: "Password1!",
      password_confirmation: "Password1!",
      terms_accepted_at: Time.current
    )
  end

  test "requires a name" do
    tag = @user.tags.build(name: "")
    assert_not tag.valid?
    assert_includes tag.errors[:name], "can't be blank"
  end

  test "enforces name maximum length of 50" do
    tag = @user.tags.build(name: "a" * 51)
    assert_not tag.valid?
    assert tag.errors[:name].any? { |e| e.include?("too long") }
  end

  test "enforces uniqueness scoped to user case-insensitive" do
    @user.tags.create!(name: "Urgent")
    duplicate = @user.tags.build(name: "urgent")
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:name], "has already been taken"
  end

  test "allows same name for different users" do
    other_user = User.create!(
      name: "Other User",
      email_address: "tag_other@example.com",
      password: "Password1!",
      password_confirmation: "Password1!",
      terms_accepted_at: Time.current
    )
    @user.tags.create!(name: "Urgent")
    tag = other_user.tags.build(name: "Urgent")
    assert tag.valid?
  end

  test "belongs to user" do
    tag = @user.tags.create!(name: "Work")
    assert_equal @user, tag.user
  end

  test "has many item_tags and todo_items through" do
    list = @user.todo_lists.create!(name: "Test List", color: "purple", template: "blank")
    item = list.todo_items.create!(name: "Tagged Item", position: 0)
    tag = @user.tags.create!(name: "Important")
    ItemTag.create!(todo_item: item, tag: tag)
    assert_includes tag.reload.todo_items, item
    assert_equal 1, tag.item_tags.count
  end
end
