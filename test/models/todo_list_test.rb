require "test_helper"

class TodoListTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(
      name: "Test User",
      email_address: "todotest@example.com",
      password: "Password1!",
      password_confirmation: "Password1!",
      terms_accepted_at: Time.current
    )
  end

  test "requires a name" do
    list = @user.todo_lists.build(name: "", color: "purple", template: "blank")
    assert_not list.valid?
    assert_includes list.errors[:name], "can't be blank"
  end

  test "enforces name maximum length" do
    list = @user.todo_lists.build(name: "a" * 101, color: "purple", template: "blank")
    assert_not list.valid?
    assert list.errors[:name].any? { |e| e.include?("too long") }
  end

  test "enforces unique name per user (case-insensitive)" do
    @user.todo_lists.create!(name: "Groceries", color: "purple", template: "blank")
    duplicate = @user.todo_lists.build(name: "groceries", color: "blue", template: "blank")
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:name], "has already been taken"
  end

  test "enforces case-insensitive uniqueness at database level" do
    @user.todo_lists.create!(name: "Groceries", color: "purple", template: "blank")
    duplicate = @user.todo_lists.build(name: "GROCERIES", color: "blue", template: "blank")
    # Skip model validation to test DB constraint directly
    duplicate.name = "GROCERIES"
    assert_raises(ActiveRecord::StatementInvalid) do
      duplicate.save(validate: false)
    end
  end

  test "allows same name for different users" do
    other_user = User.create!(
      name: "Other User",
      email_address: "other@example.com",
      password: "Password1!",
      password_confirmation: "Password1!",
      terms_accepted_at: Time.current
    )
    @user.todo_lists.create!(name: "Groceries", color: "purple", template: "blank")
    list = other_user.todo_lists.build(name: "Groceries", color: "purple", template: "blank")
    assert list.valid?
  end

  test "requires a valid color" do
    list = @user.todo_lists.build(name: "Test", color: "rainbow", template: "blank")
    assert_not list.valid?
    assert list.errors[:color].any?
  end

  test "requires a valid template" do
    list = @user.todo_lists.build(name: "Test", color: "purple", template: "invalid")
    assert_not list.valid?
    assert list.errors[:template].any?
  end

  test "icon is optional" do
    list = @user.todo_lists.build(name: "Test", color: "purple", template: "blank", icon: nil)
    assert list.valid?
  end

  test "description enforces maximum length" do
    list = @user.todo_lists.build(name: "Test", color: "purple", template: "blank", description: "a" * 501)
    assert_not list.valid?
  end

  test "apply_template! does nothing for blank template" do
    list = @user.todo_lists.create!(name: "Blank", color: "purple", template: "blank")
    list.apply_template!
    assert_equal 0, list.todo_sections.count
    assert_equal 0, list.todo_items.count
  end

  test "apply_template! creates sections and items for project template" do
    list = @user.todo_lists.create!(name: "Project", color: "blue", template: "project")
    list.apply_template!
    assert_equal 4, list.todo_sections.count
    assert_equal %w[Planning In\ Progress Review Done], list.todo_sections.map(&:name)
    assert_equal 3, list.todo_items.where(todo_section: list.todo_sections.first).count
  end

  test "apply_template! creates sections for weekly template" do
    list = @user.todo_lists.create!(name: "Weekly", color: "teal", template: "weekly")
    list.apply_template!
    assert_equal 7, list.todo_sections.count
    assert_includes list.todo_sections.map(&:name), "Monday"
    assert_includes list.todo_sections.map(&:name), "Sunday"
  end

  test "apply_template! creates sections and items for shopping template" do
    list = @user.todo_lists.create!(name: "Shopping", color: "green", template: "shopping")
    list.apply_template!
    assert_equal 6, list.todo_sections.count
    produce_section = list.todo_sections.find_by(name: "Produce")
    assert_equal 2, produce_section.todo_items.count
  end

  test "recently_updated scope orders by updated_at desc" do
    list1 = @user.todo_lists.create!(name: "First", color: "purple", template: "blank")
    list2 = @user.todo_lists.create!(name: "Second", color: "blue", template: "blank")
    list1.touch
    assert_equal list1, @user.todo_lists.recently_updated.first
  end

  test "positioned scope orders by position ascending" do
    list1 = @user.todo_lists.create!(name: "Second", color: "purple", template: "blank", position: 1)
    list2 = @user.todo_lists.create!(name: "First", color: "blue", template: "blank", position: 0)
    result = @user.todo_lists.positioned.to_a
    assert_equal list2, result.first
    assert_equal list1, result.second
  end

  test "positioned scope falls back to created_at for same position" do
    list1 = @user.todo_lists.create!(name: "Older", color: "purple", template: "blank", position: 0)
    list2 = @user.todo_lists.create!(name: "Newer", color: "blue", template: "blank", position: 0)
    result = @user.todo_lists.positioned.to_a
    assert_equal list1, result.first
    assert_equal list2, result.second
  end

  test "completion_percentage returns 0 when no items" do
    list = @user.todo_lists.create!(name: "Empty", color: "purple", template: "blank")
    assert_equal 0, list.completion_percentage
  end

  test "completion_percentage calculates correctly" do
    list = @user.todo_lists.create!(name: "Test", color: "purple", template: "blank")
    list.todo_items.create!(name: "Done", completed: true)
    list.todo_items.create!(name: "Not done", completed: false)
    assert_equal 50, list.completion_percentage
  end

  test "destroying a list cascades to sections and items" do
    list = @user.todo_lists.create!(name: "Cascade", color: "purple", template: "project")
    list.apply_template!
    section_count = list.todo_sections.count
    item_count = list.todo_items.count
    assert section_count > 0
    assert item_count > 0

    list.destroy!
    assert_equal 0, TodoSection.where(todo_list_id: list.id).count
    assert_equal 0, TodoItem.where(todo_list_id: list.id).count
  end
end
