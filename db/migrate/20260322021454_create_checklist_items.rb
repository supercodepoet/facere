class CreateChecklistItems < ActiveRecord::Migration[8.1]
  def change
    create_table :checklist_items do |t|
      t.string :name, null: false
      t.boolean :completed, default: false, null: false
      t.integer :position, default: 0, null: false
      t.integer :todo_item_id, null: false

      t.timestamps
    end

    add_index :checklist_items, :todo_item_id
    add_foreign_key :checklist_items, :todo_items
  end
end
