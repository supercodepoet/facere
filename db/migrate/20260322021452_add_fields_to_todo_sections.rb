class AddFieldsToTodoSections < ActiveRecord::Migration[8.1]
  def change
    add_column :todo_sections, :icon, :string
    add_column :todo_sections, :archived, :boolean, default: false, null: false
  end
end
