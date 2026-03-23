class ChangePriorityDefaultToNormal < ActiveRecord::Migration[8.1]
  def change
    change_column_default :todo_items, :priority, from: "none", to: "normal"
  end
end
