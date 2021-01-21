class CreateDeleteTokenTrigger < ActiveRecord::Migration[6.1]
  def up
    execute <<~SQL
      CREATE FUNCTION delete_old_rows() RETURNS trigger
          LANGUAGE plpgsql
          AS $$
      BEGIN
        DELETE FROM blacklists WHERE created_at < NOW() - INTERVAL '1 day';
        RETURN NULL;
      END;
      $$;

      CREATE TRIGGER trigger_delete_old_rows
          AFTER INSERT ON blacklists
          EXECUTE PROCEDURE delete_old_rows();
    SQL
  end

  def down
    execute <<~SQL
      DROP FUNCTION delete_old_rows() CASCADE
    SQL
  end
end
