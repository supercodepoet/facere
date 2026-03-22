class AddCaseInsensitiveUniqueIndexToTags < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL
      CREATE UNIQUE INDEX index_tags_on_user_id_and_lower_name
      ON tags(user_id, lower(name));
    SQL
  end

  def down
    execute "DROP INDEX IF EXISTS index_tags_on_user_id_and_lower_name"
  end
end
