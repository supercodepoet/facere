class CreateItemAssigneesAndRemoveAssignedTo < ActiveRecord::Migration[8.1]
  def up
    create_table :item_assignees do |t|
      t.references :todo_item, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end

    add_index :item_assignees, [ :todo_item_id, :user_id ], unique: true

    # Migrate existing assigned_to_user_id data
    execute <<~SQL
      INSERT INTO item_assignees (todo_item_id, user_id, created_at, updated_at)
      SELECT id, assigned_to_user_id, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
      FROM todo_items
      WHERE assigned_to_user_id IS NOT NULL
    SQL

    remove_reference :todo_items, :assigned_to_user, foreign_key: { to_table: :users }
  end

  def down
    add_reference :todo_items, :assigned_to_user, foreign_key: { to_table: :users }

    # Migrate back: take the first assignee for each item
    execute <<~SQL
      UPDATE todo_items
      SET assigned_to_user_id = (
        SELECT user_id FROM item_assignees
        WHERE item_assignees.todo_item_id = todo_items.id
        LIMIT 1
      )
    SQL

    drop_table :item_assignees
  end
end
