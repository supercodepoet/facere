class CreateListInvitations < ActiveRecord::Migration[8.1]
  def change
    create_table :list_invitations do |t|
      t.references :todo_list, null: false, foreign_key: true
      t.references :invited_by, null: false, foreign_key: { to_table: :users }
      t.string :email, null: false
      t.string :role, null: false, default: "editor"
      t.string :status, null: false, default: "pending"
      t.datetime :accepted_at
      t.datetime :expires_at, null: false

      t.timestamps
    end

    add_index :list_invitations, [ :todo_list_id, :email ], unique: true,
      where: "status = 'pending'", name: "index_list_invitations_unique_pending"
    add_index :list_invitations, :email
    add_index :list_invitations, [ :status, :expires_at ]
  end
end
