defmodule Elixir.Banchan.Repo.Migrations.UploadDeletionTrigger do
  use Ecto.Migration

  def up do
    execute """
    CREATE OR REPLACE FUNCTION notify_upload_deleted()
      RETURNS trigger AS $trigger$
      DECLARE
        payload TEXT;
      BEGIN
        payload := json_build_object('id', OLD.id, 'bucket', OLD.bucket, 'key', OLD.key);
        PERFORM pg_notify('upload_deleted', payload);
        RETURN NULL;
      END;
      $trigger$ LANGUAGE plpgsql;
    """

    execute """
    CREATE TRIGGER upload_deleted
      AFTER DELETE ON uploads FOR EACH ROW
      EXECUTE PROCEDURE notify_upload_deleted();
    """
  end

  def down do
    execute """
    DROP TRIGGER upload_deleted ON uploads;
    """

    execute """
    DROP FUNCTION notify_upload_deleted();
    """
  end
end
