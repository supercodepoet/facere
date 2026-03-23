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

  test "status must be in STATUSES" do
    item = @list.todo_items.build(name: "Test", position: 0, status: "invalid")
    assert_not item.valid?
    assert item.errors[:status].any?
  end

  test "priority must be in PRIORITIES" do
    item = @list.todo_items.build(name: "Test", position: 0, priority: "critical")
    assert_not item.valid?
    assert item.errors[:priority].any?
  end

  test "active scope filters out archived items" do
    @list.todo_items.create!(name: "Active", position: 0, archived: false)
    @list.todo_items.create!(name: "Archived", position: 1, archived: true)
    results = @list.todo_items.active
    assert_equal 1, results.count
    assert_equal "Active", results.first.name
  end

  test "completed scope returns only completed items" do
    @list.todo_items.create!(name: "Done", position: 0, completed: true)
    @list.todo_items.create!(name: "Not done", position: 1, completed: false)
    results = @list.todo_items.completed
    assert_equal 1, results.count
    assert_equal "Done", results.first.name
  end

  test "incomplete scope returns only incomplete items" do
    @list.todo_items.create!(name: "Done", position: 0, completed: true)
    @list.todo_items.create!(name: "Not done", position: 1, completed: false)
    results = @list.todo_items.incomplete
    assert_equal 1, results.count
    assert_equal "Not done", results.first.name
  end

  test "overdue scope returns items with past due_date that are not completed" do
    @list.todo_items.create!(name: "Overdue", position: 0, due_date: 1.day.ago, completed: false)
    @list.todo_items.create!(name: "Completed past", position: 1, due_date: 1.day.ago, completed: true)
    @list.todo_items.create!(name: "Future", position: 2, due_date: 1.day.from_now, completed: false)
    results = @list.todo_items.overdue
    assert_equal 1, results.count
    assert_equal "Overdue", results.first.name
  end

  test "toggle_completion! toggles the completed flag" do
    item = @list.todo_items.create!(name: "Toggle", position: 0, completed: false)
    item.toggle_completion!
    assert item.reload.completed?
    item.toggle_completion!
    assert_not item.reload.completed?
  end

  test "toggle_completion! syncs status to done when completed" do
    item = @list.todo_items.create!(name: "Sync", position: 0, completed: false)
    item.toggle_completion!
    assert_equal "done", item.reload.status
  end

  test "toggle_completion! syncs status to todo when uncompleted" do
    item = @list.todo_items.create!(name: "Sync", position: 0, completed: true)
    item.toggle_completion!
    assert_equal "todo", item.reload.status
  end

  test "archive! sets archived to true" do
    item = @list.todo_items.create!(name: "Archive me", position: 0)
    item.archive!
    assert item.reload.archived?
  end

  test "overdue? returns true when due_date is past and not completed" do
    item = @list.todo_items.create!(name: "Overdue", position: 0, due_date: 1.day.ago, completed: false)
    assert item.overdue?
  end

  test "overdue? returns false when completed even with past due_date" do
    item = @list.todo_items.create!(name: "Done", position: 0, due_date: 1.day.ago, completed: true)
    assert_not item.overdue?
  end

  test "due_date_style returns danger for past due date" do
    item = @list.todo_items.build(name: "Test", position: 0, due_date: 1.day.ago)
    assert_equal "danger", item.due_date_style
  end

  test "due_date_style returns warning for due date within 3 days" do
    item = @list.todo_items.build(name: "Test", position: 0, due_date: 2.days.from_now.to_date)
    assert_equal "warning", item.due_date_style
  end

  test "due_date_style returns info for due date within 14 days" do
    item = @list.todo_items.build(name: "Test", position: 0, due_date: 10.days.from_now.to_date)
    assert_equal "info", item.due_date_style
  end

  test "due_date_style returns success for due date beyond 14 days" do
    item = @list.todo_items.build(name: "Test", position: 0, due_date: 30.days.from_now.to_date)
    assert_equal "success", item.due_date_style
  end

  test "due_date_style returns nil when no due date" do
    item = @list.todo_items.build(name: "Test", position: 0, due_date: nil)
    assert_nil item.due_date_style
  end

  test "sync sets status to done when completed is set to true" do
    item = @list.todo_items.create!(name: "Sync test", position: 0, completed: false)
    item.update!(completed: true)
    assert_equal "done", item.reload.status
  end

  test "sync sets completed to true when status is set to done" do
    item = @list.todo_items.create!(name: "Sync test", position: 0, completed: false, status: "todo")
    item.update!(status: "done")
    assert item.reload.completed?
  end

  # --- Expanded status/priority tests (US1) ---

  test "on_hold is a valid status" do
    item = @list.todo_items.build(name: "Hold", position: 0, status: "on_hold")
    assert item.valid?
  end

  test "on_hold does not mark completed" do
    item = @list.todo_items.create!(name: "Hold", position: 0, status: "todo")
    item.update!(status: "on_hold")
    assert_not item.reload.completed?
  end

  test "changing from done to on_hold unmarks completed" do
    item = @list.todo_items.create!(name: "Hold", position: 0, status: "done", completed: true)
    item.update!(status: "on_hold")
    assert_not item.reload.completed?
  end

  test "urgent is a valid priority" do
    item = @list.todo_items.build(name: "Urgent", position: 0, priority: "urgent")
    assert item.valid?
  end

  test "medium is a valid priority" do
    item = @list.todo_items.build(name: "Medium", position: 0, priority: "medium")
    assert item.valid?
  end

  test "normal is no longer a valid priority" do
    item = @list.todo_items.build(name: "Normal", position: 0, priority: "normal")
    assert_not item.valid?
  end

  test "status_label returns human-readable labels" do
    item = @list.todo_items.build(name: "Test", position: 0, status: "in_progress")
    assert_equal "In Progress", item.status_label
  end

  test "priority_label returns human-readable labels" do
    item = @list.todo_items.build(name: "Test", position: 0, priority: "urgent")
    assert_equal "Urgent", item.priority_label
  end

  test "priority_color returns correct hex for each priority" do
    assert_equal "#EF4444", @list.todo_items.build(priority: "urgent").priority_color
    assert_equal "#F59E0B", @list.todo_items.build(priority: "high").priority_color
    assert_equal "#3B82F6", @list.todo_items.build(priority: "medium").priority_color
    assert_equal "#14B8A6", @list.todo_items.build(priority: "low").priority_color
    assert_equal "#A1A1AA", @list.todo_items.build(priority: "none").priority_color
  end

  test "status_color returns correct hex for each status" do
    assert_equal "#A1A1AA", @list.todo_items.build(status: "todo").status_color
    assert_equal "#8B5CF6", @list.todo_items.build(status: "in_progress").status_color
    assert_equal "#F59E0B", @list.todo_items.build(status: "on_hold").status_color
    assert_equal "#14B8A6", @list.todo_items.build(status: "done").status_color
  end

  test "due_date_display formats date correctly" do
    item = @list.todo_items.build(name: "Test", position: 0, due_date: Date.new(2026, 3, 10))
    assert_equal "March 10, 2026", item.due_date_display
  end

  test "due_date_countdown shows days left for future date" do
    item = @list.todo_items.build(name: "Test", position: 0, due_date: 5.days.from_now.to_date)
    assert_match(/5 days left/, item.due_date_countdown)
  end

  test "due_date_countdown shows overdue for past date" do
    item = @list.todo_items.build(name: "Test", position: 0, due_date: 3.days.ago.to_date)
    assert_match(/3 days overdue/, item.due_date_countdown)
  end

  test "checklist_progress returns ratio string" do
    item = @list.todo_items.create!(name: "Progress", position: 0)
    item.checklist_items.create!(name: "Done", position: 0, completed: true)
    item.checklist_items.create!(name: "Pending", position: 1, completed: false)
    assert_equal "1/2", item.checklist_progress
  end
end
