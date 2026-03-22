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

  test "icon can be set" do
    section = @list.todo_sections.create!(name: "With Icon", position: 0, icon: "star")
    assert_equal "star", section.reload.icon
  end

  test "active scope filters archived sections" do
    @list.todo_sections.create!(name: "Active", position: 0, archived: false)
    @list.todo_sections.create!(name: "Archived", position: 1, archived: true)
    results = @list.all_todo_sections.active
    assert_equal 1, results.count
    assert_equal "Active", results.first.name
  end

  test "archive! sets archived true on section and all its items" do
    section = @list.todo_sections.create!(name: "To Archive", position: 0)
    item1 = @list.todo_items.create!(name: "Item 1", todo_section: section, position: 0)
    item2 = @list.todo_items.create!(name: "Item 2", todo_section: section, position: 1)
    section.archive!
    assert section.reload.archived?
    assert item1.reload.archived?
    assert item2.reload.archived?
  end

  test "active_item_count returns count of non-archived items" do
    section = @list.todo_sections.create!(name: "Count Test", position: 0)
    @list.todo_items.create!(name: "Active Item", todo_section: section, position: 0, archived: false)
    @list.todo_items.create!(name: "Archived Item", todo_section: section, position: 1, archived: true)
    assert_equal 1, section.active_item_count
  end
end
