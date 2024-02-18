defmodule Banchan.Uploads.UploadDeleteListener do
  @moduledoc """
  Listens for Postgres notifications that are fired whenever an Upload row is
  deleted, and queues deletion of the corresponding data.
  """
  use GenServer

  alias Banchan.Repo
  alias Banchan.Uploads.Upload
  alias Banchan.Workers.UploadDeleter

  @channel "upload_deleted"

  def start_link(init_args) do
    GenServer.start_link(__MODULE__, [init_args], name: __MODULE__)
  end

  def init(_args) do
    repo_config = Repo.config()

    {:ok, pid} = Postgrex.Notifications.start_link(repo_config)
    {:ok, ref} = Postgrex.Notifications.listen(pid, @channel)

    {:ok, {pid, ref}}
  end

  def handle_info({:notification, _pid, _ref, @channel, payload}, state) do
    payload = Jason.decode!(payload)

    UploadDeleter.queue_data_deletion(%Upload{
      id: payload["id"],
      bucket: payload["bucket"],
      key: payload["key"]
    })

    {:noreply, state}
  end
end
