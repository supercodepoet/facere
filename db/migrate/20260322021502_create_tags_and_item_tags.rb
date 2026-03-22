class CreateTagsAndItemTags < ActiveRecord::Migration[8.1]
  def change
    create_table :tags do |t|
      t.string :name, null: false
      t.string :color
      t.integer :user_id, null: false
      t.timestamps
    end

    add_foreign_key :tags, :users
    add_index :tags, :user_id

    create_table :item_tags do |t|
      t.integer :todo_item_id, null: false
      t.integer :tag_id, null: false
      t.timestamps
    end

    add_foreign_key :item_tags, :todo_items
    add_foreign_key :item_tags, :tags
    add_index :item_tags, [ :todo_item_id, :tag_id ], unique: true
    add_index :item_tags, :tag_id
  end
end
