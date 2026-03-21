class CreateTodoLists < ActiveRecord::Migration[8.1]
  def change
    create_table :todo_lists do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      t.string :color, null: false, default: "purple"
      t.string :icon
      t.text :description
      t.string :template, null: false, default: "blank"

      t.timestamps
    end

    add_index :todo_lists, [ :user_id, :name ], unique: true
  end
end
