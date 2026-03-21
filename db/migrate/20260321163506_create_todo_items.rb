class CreateTodoItems < ActiveRecord::Migration[8.1]
  def change
    create_table :todo_items do |t|
      t.references :todo_list, null: false, foreign_key: true
      t.references :todo_section, foreign_key: true
      t.string :name, null: false
      t.boolean :completed, null: false, default: false
      t.integer :position, null: false, default: 0

      t.timestamps
    end
  end
end
