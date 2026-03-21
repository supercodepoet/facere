class AddCaseInsensitiveUniqueIndexToTodoLists < ActiveRecord::Migration[8.1]
  def up
    remove_index :todo_lists, column: [ :user_id, :name ], if_exists: true

    execute <<~SQL
      CREATE UNIQUE INDEX index_todo_lists_on_user_id_and_lower_name
      ON todo_lists(user_id, lower(name));
    SQL
  end

  def down
    execute "DROP INDEX IF EXISTS index_todo_lists_on_user_id_and_lower_name"

    add_index :todo_lists, [ :user_id, :name ], unique: true
  end
end
