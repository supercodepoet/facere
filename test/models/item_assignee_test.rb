require "test_helper"

class ItemAssigneeTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(
      name: "Test User",
      email_address: "assignee_owner@example.com",
      password: "Password1!",
      password_confirmation: "Password1!",
      terms_accepted_at: Time.current,
      email_verified_at: Time.current
    )
    @collaborator = User.create!(
      name: "Collaborator",
      email_address: "assignee_collab@example.com",
      password: "Password1!",
      password_confirmation: "Password1!",
      terms_accepted_at: Time.current,
      email_verified_at: Time.current
    )
    @list = @user.todo_lists.create!(name: "Test List", color: "purple", template: "blank")
    @item = @list.todo_items.create!(name: "Test Item")
  end

  test "belongs to todo_item" do
    assignee = @item.item_assignees.create!(user: @collaborator)
    assert_equal @item, assignee.todo_item
  end

  test "belongs to user" do
    assignee = @item.item_assignees.create!(user: @collaborator)
    assert_equal @collaborator, assignee.user
  end

  test "enforces uniqueness of user_id scoped to todo_item_id" do
    @item.item_assignees.create!(user: @collaborator)
    duplicate = @item.item_assignees.build(user: @collaborator)
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:user_id], "is already assigned to this item"
  end

  test "valid creation" do
    assignee = @item.item_assignees.build(user: @collaborator)
    assert assignee.valid?
    assert assignee.save
  end
end
