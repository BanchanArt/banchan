defmodule Banchan.Repo.Migrations.FixUploadRefs do
  use Ecto.Migration

  def change do
    execute(
      # Up
      fn ->
        repo().query(
          """
          ALTER TABLE event_attachments
            DROP CONSTRAINT event_attachments_upload_id_fkey,
            ADD CONSTRAINT event_attachments_upload_id_fkey
            FOREIGN KEY (upload_id) REFERENCES uploads(id) ON DELETE SET NULL;
          """,
          [],
          log: false
        )

        repo().query(
          """
          ALTER TABLE event_attachments
            DROP CONSTRAINT event_attachments_preview_id_fkey,
            ADD CONSTRAINT event_attachments_preview_id_fkey
            FOREIGN KEY (preview_id) REFERENCES uploads(id) ON DELETE SET NULL;
          """,
          [],
          log: false
        )
      end,
      fn ->
        # Down
        repo().query(
          """
          ALTER TABLE event_attachments
            DROP CONSTRAINT event_attachments_upload_id_fkey,
            ADD CONSTRAINT event_attachments_upload_id_fkey
            FOREIGN KEY (upload_id) REFERENCES uploads(id) ON DELETE CASCADE;
          """,
          [],
          log: false
        )

        repo().query(
          """
          ALTER TABLE event_attachments
            DROP CONSTRAINT event_attachments_preview_id_fkey,
            ADD CONSTRAINT event_attachments_preview_id_fkey
            FOREIGN KEY (preview_id) REFERENCES uploads(id) ON DELETE CASCADE;
          """,
          [],
          log: false
        )
      end
    )
  end
end
