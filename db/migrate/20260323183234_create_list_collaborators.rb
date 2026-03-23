class CreateListCollaborators < ActiveRecord::Migration[8.1]
  def change
    create_table :list_collaborators do |t|
      t.references :todo_list, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :role, null: false, default: "editor"

      t.timestamps
    end

    add_index :list_collaborators, [ :todo_list_id, :user_id ], unique: true
  end
end
