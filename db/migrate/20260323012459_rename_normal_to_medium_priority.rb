class RenameNormalToMediumPriority < ActiveRecord::Migration[8.1]
  def up
    execute "UPDATE todo_items SET priority = 'medium' WHERE priority = 'normal'"
    change_column_default :todo_items, :priority, from: "normal", to: "medium"
  end

  def down
    execute "UPDATE todo_items SET priority = 'normal' WHERE priority = 'medium'"
    change_column_default :todo_items, :priority, from: "medium", to: "normal"
  end
end
