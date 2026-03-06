class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :email_address, null: false
      t.string :password_digest
      t.string :name, null: false
      t.datetime :terms_accepted_at
      t.datetime :email_verified_at
      t.datetime :email_verification_grace_expires_at
      t.integer :failed_login_attempts, null: false, default: 0
      t.integer :lockout_count, null: false, default: 0
      t.datetime :locked_until

      t.timestamps
    end
    add_index :users, :email_address, unique: true
  end
end
