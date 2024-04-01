defmodule Banchan.Works.Notifications do
  @moduledoc """
  Notifications related to Works (new works, etc).
  """
  import Ecto.Query, warn: false

  alias Banchan.Notifications
  alias Banchan.Repo
  alias Banchan.Studios
  alias Banchan.Works.Work

  # Unfortunate, but needed for crafting URLs for notifications
  use BanchanWeb, :verified_routes

  def work_created(%Work{} = work, actor \\ nil) do
    Notifications.with_task(fn ->
      {:ok, _} =
        Repo.transaction(fn ->
          work = Repo.preload(work, :studio)

          studio = work.studio

          subs = Studios.Notifications.stream_followers(studio)

          url = url(~p"/studios/#{studio.handle}/works/#{work.public_id}")

          {:safe, safe_url} = Phoenix.HTML.html_escape(url)

          Notifications.notify_subscribers!(
            actor,
            subs,
            %Notifications.UserNotification{
              type: "work_created",
              title: "New work published",
              short_body: "#{studio.name} published a new work.",
              text_body: "#{studio.name} published a new work, #{work.title}:\n\n#{url}",
              html_body:
                "<p>#{studio.name} published a new work: <a href=\"#{safe_url}\">#{work.title}</a></p>",
              url: url,
              read: false
            }
          )
        end)
    end)
  end
end
