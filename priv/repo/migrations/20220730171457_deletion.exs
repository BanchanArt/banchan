defmodule Banchan.Repo.Migrations.Deletion do
  use Ecto.Migration

  def change do
    # TODO: Merge this entire migration into the previous migrations when
    # we're ready for another hard reset. This is super messy.
    alter table(:users) do
      add :deactivated_at, :naive_datetime
    end

    alter table(:studios) do
      add :archived_at, :naive_datetime
      add :deleted_at, :naive_datetime
    end

    alter table(:offerings) do
      add :deleted_at, :naive_datetime
    end

    # Various tables had messed up fkey constraints, and this fixes them up.
    execute(
      # Up
      fn ->
        repo().query(
          """
          ALTER TABLE disable_history
            DROP CONSTRAINT disable_history_disabled_by_id_fkey,
            ADD CONSTRAINT disable_history_disabled_by_id_fkey
            FOREIGN KEY (disabled_by_id) REFERENCES users(id) ON DELETE SET NULL;
          """,
          [],
          log: :info
        )

        repo().query(
          """
          ALTER TABLE disable_history
            DROP CONSTRAINT disable_history_lifted_by_id_fkey,
            ADD CONSTRAINT disable_history_lifted_by_id_fkey
            FOREIGN KEY (lifted_by_id) REFERENCES users(id) ON DELETE SET NULL;
          """,
          [],
          log: :info
        )

        repo().query(
          """
          ALTER TABLE users_studios
            DROP CONSTRAINT users_studios_user_id_fkey,
            ADD CONSTRAINT users_studios_user_id_fkey
            FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;
          """,
          [],
          log: :info
        )

        repo().query(
          """
          ALTER TABLE users_studios
            DROP CONSTRAINT users_studios_studio_id_fkey,
            ADD CONSTRAINT users_studios_studio_id_fkey
            FOREIGN KEY (studio_id) REFERENCES studios(id) ON DELETE CASCADE;
          """,
          [],
          log: :info
        )

        repo().query(
          """
          ALTER TABLE studio_payouts
            ALTER COLUMN actor_id DROP NOT NULL;
          """,
          [],
          log: :info
        )

        repo().query(
          """
          ALTER TABLE studio_payouts
            DROP CONSTRAINT studio_payouts_actor_id_fkey,
            ADD CONSTRAINT studio_payouts_actor_id_fkey
            FOREIGN KEY (actor_id) REFERENCES users(id) ON DELETE SET NULL;
          """,
          [],
          log: :info
        )

        repo().query(
          """
          ALTER TABLE studio_payouts
            DROP CONSTRAINT studio_payouts_studio_id_fkey,
            ADD CONSTRAINT studio_payouts_studio_id_fkey
            FOREIGN KEY (studio_id) REFERENCES studios(id) ON DELETE CASCADE;
          """,
          [],
          log: :info
        )

        repo().query(
          """
          ALTER TABLE commission_events
            ALTER COLUMN actor_id DROP NOT NULL;
          """,
          [],
          log: :info
        )

        repo().query(
          """
          ALTER TABLE commission_events
            DROP CONSTRAINT commission_events_actor_id_fkey,
            ADD CONSTRAINT commission_events_actor_id_fkey
            FOREIGN KEY (actor_id) REFERENCES users(id) ON DELETE SET NULL;
          """,
          [],
          log: :info
        )

        repo().query(
          """
          ALTER TABLE commission_invoices
            DROP CONSTRAINT commission_invoices_refunded_by_id_fkey,
            ADD CONSTRAINT commission_invoices_refunded_by_id_fkey
            FOREIGN KEY (refunded_by_id) REFERENCES users(id) ON DELETE SET NULL;
          """,
          [],
          log: :info
        )

        repo().query(
          """
          ALTER TABLE commission_invoices
            DROP CONSTRAINT commission_invoices_client_id_fkey,
            ADD CONSTRAINT commission_invoices_client_id_fkey
            FOREIGN KEY (client_id) REFERENCES users(id) ON DELETE SET NULL;
          """,
          [],
          log: :info
        )

        repo().query(
          """
          ALTER TABLE comment_history
            ALTER COLUMN changed_by_id DROP NOT NULL;
          """,
          [],
          log: :info
        )

        repo().query(
          """
          ALTER TABLE comment_history
            DROP CONSTRAINT comment_history_changed_by_id_fkey,
            ADD CONSTRAINT comment_history_changed_by_id_fkey
            FOREIGN KEY (changed_by_id) REFERENCES users(id) ON DELETE SET NULL;
          """,
          [],
          log: :info
        )

        repo().query(
          """
          ALTER TABLE studio_disable_history
            DROP CONSTRAINT studio_disable_history_disabled_by_id_fkey,
            ADD CONSTRAINT studio_disable_history_disabled_by_id_fkey
            FOREIGN KEY (disabled_by_id) REFERENCES users(id) ON DELETE SET NULL;
          """,
          [],
          log: :info
        )

        repo().query(
          """
          ALTER TABLE studio_disable_history
            DROP CONSTRAINT studio_disable_history_lifted_by_id_fkey,
            ADD CONSTRAINT studio_disable_history_lifted_by_id_fkey
            FOREIGN KEY (lifted_by_id) REFERENCES users(id) ON DELETE SET NULL;
          """,
          [],
          log: :info
        )

        repo().query(
          """
          ALTER TABLE offerings
            DROP CONSTRAINT offerings_studio_id_fkey,
            ADD CONSTRAINT offerings_studio_id_fkey
            FOREIGN KEY (studio_id) REFERENCES studios(id) ON DELETE CASCADE;
          """,
          [],
          log: :info
        )
      end,

      # Down
      fn ->
        repo().query(
          """
          ALTER TABLE disable_history
            DROP CONSTRAINT disable_history_disabled_by_id_fkey,
            ADD CONSTRAINT disable_history_disabled_by_id_fkey
            FOREIGN KEY (disabled_by_id) REFERENCES users(id) ON DELETE CASCADE;
          """,
          [],
          log: :info
        )

        repo().query(
          """
          ALTER TABLE disable_history
            DROP CONSTRAINT disable_history_lifted_by_id_fkey,
            ADD CONSTRAINT disable_history_lifted_by_id_fkey
            FOREIGN KEY (lifted_by_id) REFERENCES users(id) ON DELETE CASCADE;
          """,
          [],
          log: :info
        )

        repo().query(
          """
          ALTER TABLE users_studios
            DROP CONSTRAINT users_studios_user_id_fkey,
            ADD CONSTRAINT users_studios_user_id_fkey
            FOREIGN KEY (user_id) REFERENCES users(id);
          """,
          [],
          log: :info
        )

        repo().query(
          """
          ALTER TABLE users_studios
            DROP CONSTRAINT users_studios_studio_id_fkey,
            ADD CONSTRAINT users_studios_studio_id_fkey
            FOREIGN KEY (studio_id) REFERENCES studios(id);
          """,
          [],
          log: :info
        )

        repo().query(
          """
          ALTER TABLE studio_payouts
            ALTER COLUMN actor_id SET NOT NULL;
          """,
          [],
          log: :info
        )

        repo().query(
          """
          ALTER TABLE studio_payouts
            DROP CONSTRAINT studio_payouts_actor_id_fkey,
            ADD CONSTRAINT studio_payouts_actor_id_fkey
            FOREIGN KEY (actor_id) REFERENCES users(id);
          """,
          [],
          log: :info
        )

        repo().query(
          """
          ALTER TABLE studio_payouts
            DROP CONSTRAINT studio_payouts_studio_id_fkey,
            ADD CONSTRAINT studio_payouts_studio_id_fkey
            FOREIGN KEY (studio_id) REFERENCES studios(id);
          """,
          [],
          log: :info
        )

        repo().query(
          """
          ALTER TABLE commission_events
            ALTER COLUMN actor_id SET NOT NULL;
          """,
          [],
          log: :info
        )

        repo().query(
          """
          ALTER TABLE commission_events
            DROP CONSTRAINT commission_events_actor_id_fkey,
            ADD CONSTRAINT commission_events_actor_id_fkey
            FOREIGN KEY (actor_id) REFERENCES users(id);
          """,
          [],
          log: :info
        )

        repo().query(
          """
          ALTER TABLE commission_invoices
            DROP CONSTRAINT commission_invoices_refunded_by_id_fkey,
            ADD CONSTRAINT commission_invoices_refunded_by_id_fkey
            FOREIGN KEY (refunded_by_id) REFERENCES users(id);
          """,
          [],
          log: :info
        )

        repo().query(
          """
          ALTER TABLE commission_invoices
            DROP CONSTRAINT commission_invoices_client_id_fkey,
            ADD CONSTRAINT commission_invoices_client_id_fkey
            FOREIGN KEY (client_id) REFERENCES users(id);
          """,
          [],
          log: :info
        )

        repo().query(
          """
          ALTER TABLE comment_history
            ALTER COLUMN changed_by_id SET NOT NULL;
          """,
          [],
          log: :info
        )

        repo().query(
          """
          ALTER TABLE comment_history
            DROP CONSTRAINT comment_history_changed_by_id_fkey,
            ADD CONSTRAINT comment_history_changed_by_id_fkey
            FOREIGN KEY (changed_by_id) REFERENCES users(id);
          """,
          [],
          log: :info
        )

        repo().query(
          """
          ALTER TABLE studio_disable_history
            DROP CONSTRAINT studio_disable_history_disabled_by_id_fkey,
            ADD CONSTRAINT studio_disable_history_disabled_by_id_fkey
            FOREIGN KEY (disabled_by_id) REFERENCES users(id) ON DELETE CASCADE;
          """,
          [],
          log: :info
        )

        repo().query(
          """
          ALTER TABLE studio_disable_history
            DROP CONSTRAINT studio_disable_history_lifted_by_id_fkey,
            ADD CONSTRAINT studio_disable_history_lifted_by_id_fkey
            FOREIGN KEY (lifted_by_id) REFERENCES users(id) ON DELETE CASCADE;
          """,
          [],
          log: :info
        )

        repo().query(
          """
          ALTER TABLE offerings
            DROP CONSTRAINT offerings_studio_id_fkey,
            ADD CONSTRAINT offerings_studio_id_fkey
            FOREIGN KEY (studio_id) REFERENCES studios(id);
          """,
          [],
          log: :info
        )
      end
    )
  end
end
