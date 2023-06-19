defmodule BanchanWeb.AccountDisabledLive do
  @moduledoc """
  Page shown to disabled users.
  """
  use BanchanWeb, :surface_view

  alias Banchan.Repo

  alias BanchanWeb.Components.{Layout, Markdown}

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_user && Repo.preload(socket.assigns.current_user, :disable_info)

    if is_nil(user) || is_nil(user.disable_info) do
      {:ok, socket |> push_navigate(to: Routes.login_path(Endpoint, :new))}
    else
      {:ok, socket |> assign(current_user: user)}
    end
  end

  @impl true
  def render(assigns) do
    ~F"""
    <Layout flashes={@flash} padding={0}>
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
