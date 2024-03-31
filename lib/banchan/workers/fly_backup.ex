defmodule Banchan.Workers.FlyBackup do
  @moduledoc """
  Periodic worker that connects to a fly.io database and runs a backup
  command, making sure all relevant authentication is done.

  Backups are based on `wal-g`, and the setup is documented at
  https://community.fly.io/t/point-in-time-backups-using-postgres-and-wal-g/6867

  This module only takes care of the periodic snapshot backups, rather than
  the streaming ones.
  """
  use Oban.Worker,
    queue: :backup,
    unique: [period: 60],
    max_attempts: 5,
    tags: ["backup", "system"]

  require Logger

  alias Banchan.Workers.Mailer

  @impl Oban.Worker
  def perform(%_{args: _}) do
    run_backup()
  end

  def run_backup do
    case Application.fetch_env(:banchan, Banchan.Workers.FlyBackup) do
      {:ok, config} ->
        case {Keyword.get(config, :fly_access_token), Keyword.get(config, :fly_db_app)} do
          {token, app} when is_nil(token) or is_nil(app) ->
            Logger.info("FlyBackup not configured (app or token missing), skipping backup.")

          {token, app} ->
            do_backup(token, app)
        end

      :error ->
        Logger.info("Not FlyBackup config found, skipping backup.")
        :ok
    end
  end

  defp do_backup(token, fly_app) do
    config_path = Path.join([System.user_home!(), ".fly", "config.yml"])

    Logger.info("Running backup")

    with :ok <-
           File.write(config_path, """
           access_token: #{token}
           """),
         {output, code} <-
           System.cmd(
             "fly",
             [
               "ssh",
               "console",
               "-a",
               fly_app,
               "-C",
               "bash -c \"PGUSER=postgres PGPASSWORD=$OPERATOR_PASSWORD wal-g backup-push /data/postgres\""
             ],
             stderr_to_stdout: true
           ),
         {backup_list, 0} <-
           System.cmd(
             "fly",
             [
               "ssh",
               "console",
               "-a",
               fly_app,
               "-C",
               "bash -c \"PGUSER=postgres PGPASSWORD=$OPERATOR_PASSWORD wal-g backup-list\""
             ],
             stderr_to_stdout: true
           ),
         {wal_show, 0} <-
           System.cmd(
             "fly",
             [
               "ssh",
               "console",
               "-a",
               fly_app,
               "-C",
               "bash -c \"PGUSER=postgres PGPASSWORD=$OPERATOR_PASSWORD wal-g wal-show\""
             ],
             stderr_to_stdout: true
           ),
         {verify_integrity, 0} <-
           System.cmd(
             "fly",
             [
               "ssh",
               "console",
               "-a",
               fly_app,
               "-C",
               "bash -c \"PGUSER=postgres PGPASSWORD=$OPERATOR_PASSWORD wal-g wal-verify integrity\""
             ],
             stderr_to_stdout: true
           ),
         {verify_timeline, 0} <-
           System.cmd(
             "fly",
             [
               "ssh",
               "console",
               "-a",
               fly_app,
               "-C",
               "bash -c \"PGUSER=postgres PGPASSWORD=$OPERATOR_PASSWORD wal-g wal-verify timeline\""
             ],
             stderr_to_stdout: true
           ),
         {:ok, _} <-
           File.rm_rf(config_path) do
      {output <> backup_list <> wal_show <> verify_integrity <> verify_timeline, code}
    end
    |> case do
      {:error, error} ->
        notify_completed("Backup operation errored", "N/A", error)
        {:error, error}

      {output, 0} ->
        notify_completed("Backup operation succeeded", 0, output)
        Logger.info("Backup succeeded: #{output}")
        :ok

      {output, code} ->
        if code == 1 && String.match?(output, ~r/Error: The handle is invalid/) &&
             String.match?(output, ~r/Write backup with name/) do
          # For some reason, the backup command over fly ssh complains about
          # the handle being invalid, *after* already succeeding.
          # It only seems to happen when I test this on Windows, though.
          notify_completed("Backup operation succeeded suspiciously?", code, output)
          Logger.warning("Backup succeeded with bad error code #{code}: #{output}")
          :ok
        else
          notify_completed("Backup operation failed", code, output)
          {:error, "Backup failed with code #{code}: #{output}"}
        end
    end
  end

  defp notify_completed(title, code, output) do
    Mailer.new_email(
      Application.get_env(:banchan, :ops_email, "ops@banchan.art"),
      title,
      BanchanWeb.Email.Ops,
      :backup_completed,
      code: code,
      output: output
    )
    |> Mailer.deliver()
  end
end
