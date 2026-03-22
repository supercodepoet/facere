class CreateComments < ActiveRecord::Migration[8.1]
  def change
    create_table :comments do |t|
      t.text :body, null: false
      t.integer :todo_item_id, null: false
      t.integer :user_id, null: false

      t.timestamps
    end

    add_foreign_key :comments, :todo_items
    add_foreign_key :comments, :users
    add_index :comments, :todo_item_id
    add_index :comments, :user_id
  end
end
