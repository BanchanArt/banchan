defmodule BanchanWeb.AccountDisabledLive do
  @moduledoc """
  Page shown to disabled users.
  """
  use BanchanWeb, :surface_view

  alias Banchan.Repo

  alias BanchanWeb.Components.{Layout, Markdown}

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket |> assign(current_user: socket.assigns.current_user |> Repo.preload(:disable_info))}
  end

  @impl true
  def handle_params(_params, uri, socket) do
    {:noreply, socket |> assign(uri: uri)}
  end

  @impl true
  def render(assigns) do
    ~F"""
    <Layout uri={@uri} padding={0} current_user={@current_user} flashes={@flash}>
      <div class="w-full h-full md:bg-base-300">
        <div class="max-w-xl w-full rounded-xl p-10 mx-auto md:my-10 bg-base-100">
          <div class="text-xl">
            Account Disabled
          </div>
          <div :if={@current_user.disable_info.disabled_until}>
            Your account has been disabled until {@current_user.disabled_until |> Timex.to_datetime() |> Timex.format!("{RFC822}")}.
          </div>
          <div :if={is_nil(@current_user.disable_info.disabled_until)}>
            Your account has been indefinitely disabled.
          </div>
          <div :if={@current_user.disable_info.disabled_reason}>
            <div class="divider" />
            <div class="text-xl">
              Reason
            </div>
            <Markdown content={@current_user.disable_info.disabled_reason} />
          </div>
        </div>
      </div>
    </Layout>
    """
  end
end
