require "test_helper"

class ChecklistItemTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(
      name: "Test User",
      email_address: "checklist_test@example.com",
      password: "Password1!",
      password_confirmation: "Password1!",
      terms_accepted_at: Time.current
    )
    @list = @user.todo_lists.create!(name: "Test List", color: "purple", template: "blank")
    @item = @list.todo_items.create!(name: "Test Item", position: 0)
  end

  test "requires a name" do
    checklist_item = @item.checklist_items.build(name: "", position: 0)
    assert_not checklist_item.valid?
    assert_includes checklist_item.errors[:name], "can't be blank"
  end

  test "enforces name maximum length of 255" do
    checklist_item = @item.checklist_items.build(name: "a" * 256, position: 0)
    assert_not checklist_item.valid?
    assert checklist_item.errors[:name].any? { |e| e.include?("too long") }
  end

  test "requires a valid position" do
    checklist_item = @item.checklist_items.build(name: "Test", position: -1)
    assert_not checklist_item.valid?
    assert checklist_item.errors[:position].any?
  end

  test "belongs to todo_item" do
    checklist_item = @item.checklist_items.create!(name: "Sub task", position: 0)
    assert_equal @item, checklist_item.todo_item
  end

  test "toggle_completion! toggles completed" do
    checklist_item = @item.checklist_items.create!(name: "Toggle me", position: 0)
    assert_not checklist_item.completed?
    checklist_item.toggle_completion!
    assert checklist_item.reload.completed?
    checklist_item.toggle_completion!
    assert_not checklist_item.reload.completed?
  end
end
