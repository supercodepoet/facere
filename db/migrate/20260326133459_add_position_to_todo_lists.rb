class AddPositionToTodoLists < ActiveRecord::Migration[8.1]
  def up
    add_column :todo_lists, :position, :integer, default: 0, null: false

    # Backfill positions based on creation order per user
    execute <<~SQL
      UPDATE todo_lists
      SET position = (
        SELECT COUNT(*)
        FROM todo_lists AS t2
        WHERE t2.user_id = todo_lists.user_id
          AND t2.created_at < todo_lists.created_at
      )
    SQL
  end

  def down
    remove_column :todo_lists, :position
  end
end
