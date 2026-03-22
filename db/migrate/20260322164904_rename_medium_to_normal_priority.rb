class RenameMediumToNormalPriority < ActiveRecord::Migration[8.1]
  def up
    execute "UPDATE todo_items SET priority = 'normal' WHERE priority = 'medium'"
  end

  def down
    execute "UPDATE todo_items SET priority = 'medium' WHERE priority = 'normal'"
  end
end
