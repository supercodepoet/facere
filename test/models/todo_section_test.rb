require "test_helper"

class TodoSectionTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(
      name: "Test User",
      email_address: "section_test@example.com",
      password: "Password1!",
      password_confirmation: "Password1!",
      terms_accepted_at: Time.current
    )
    @list = @user.todo_lists.create!(name: "Test List", color: "purple", template: "blank")
  end

  test "requires a name" do
    section = @list.todo_sections.build(name: "", position: 0)
    assert_not section.valid?
    assert_includes section.errors[:name], "can't be blank"
  end

  test "enforces name maximum length" do
    section = @list.todo_sections.build(name: "a" * 101, position: 0)
    assert_not section.valid?
  end

  test "requires a non-negative position" do
    section = @list.todo_sections.build(name: "Test", position: -1)
    assert_not section.valid?
  end

  test "orders by position by default" do
    @list.todo_sections.create!(name: "Second", position: 1)
    @list.todo_sections.create!(name: "First", position: 0)
    assert_equal "First", @list.todo_sections.first.name
  end

  test "destroying section cascades to items" do
    section = @list.todo_sections.create!(name: "Cascade", position: 0)
    @list.todo_items.create!(name: "Item", todo_section: section, position: 0)
    section.destroy!
    assert_equal 0, TodoItem.where(todo_section_id: section.id).count
  end
end
