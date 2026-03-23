require "test_helper"

class NotifyPersonTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(
      name: "Notify Model Test",
      email_address: "notify_model@example.com",
      password: "Password1!",
      password_confirmation: "Password1!",
      terms_accepted_at: Time.current
    )
    @list = @user.todo_lists.create!(name: "Test List", color: "purple", template: "blank")
    @item = @list.todo_items.create!(name: "Test Item", position: 0, status: "todo", priority: "none")
  end

  test "validates uniqueness of user per todo_item" do
    NotifyPerson.create!(todo_item: @item, user: @user)
    duplicate = NotifyPerson.new(todo_item: @item, user: @user)
    assert_not duplicate.valid?
    assert duplicate.errors[:user_id].any?
  end

  test "belongs to todo_item" do
    np = NotifyPerson.create!(todo_item: @item, user: @user)
    assert_equal @item, np.todo_item
  end

  test "belongs to user" do
    np = NotifyPerson.create!(todo_item: @item, user: @user)
    assert_equal @user, np.user
  end
end
