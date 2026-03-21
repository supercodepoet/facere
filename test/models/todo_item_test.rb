require "test_helper"

class TodoItemTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(
      name: "Test User",
      email_address: "item_test@example.com",
      password: "Password1!",
      password_confirmation: "Password1!",
      terms_accepted_at: Time.current
    )
    @list = @user.todo_lists.create!(name: "Test List", color: "purple", template: "blank")
  end

  test "requires a name" do
    item = @list.todo_items.build(name: "", position: 0)
    assert_not item.valid?
    assert_includes item.errors[:name], "can't be blank"
  end

  test "enforces name maximum length" do
    item = @list.todo_items.build(name: "a" * 256, position: 0)
    assert_not item.valid?
  end

  test "section is optional" do
    item = @list.todo_items.build(name: "No section", position: 0, todo_section: nil)
    assert item.valid?
  end

  test "defaults completed to false" do
    item = @list.todo_items.create!(name: "Test", position: 0)
    assert_equal false, item.completed
  end

  test "orders by position by default" do
    @list.todo_items.create!(name: "Second", position: 1)
    @list.todo_items.create!(name: "First", position: 0)
    assert_equal "First", @list.todo_items.first.name
  end
end
