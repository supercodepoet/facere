class AddFieldsToTodoItems < ActiveRecord::Migration[8.1]
  def change
    add_column :todo_items, :status, :string, default: "todo", null: false
    add_column :todo_items, :due_date, :date
    add_column :todo_items, :priority, :string, default: "none", null: false
    add_column :todo_items, :archived, :boolean, default: false, null: false
    add_column :todo_items, :assigned_to_user_id, :integer
    add_foreign_key :todo_items, :users, column: :assigned_to_user_id
  end
end
