class CreateTwoFactorCredentials < ActiveRecord::Migration[8.1]
  def change
    create_table :two_factor_credentials do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.string :otp_secret, null: false
      t.boolean :enabled, null: false, default: false

      t.timestamps
    end
  end
end
