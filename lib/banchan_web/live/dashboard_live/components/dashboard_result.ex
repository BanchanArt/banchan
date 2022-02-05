defmodule BanchanWeb.DashboardLive.Components.DashboardResult do
  @moduledoc """
  Component for displaying dashboard result rows.
  """
  use BanchanWeb, :component

  alias Banchan.Commissions.Common

  alias Surface.Components.LiveRedirect

  alias BanchanWeb.Endpoint

  prop result, :struct, required: true

  def render(assigns) do
    ~F"""
    <LiveRedirect
      class="text-xl hover:text-secondary"
      to={Routes.studio_commissions_show_path(Endpoint, :show, @result.studio_handle, @result.public_id)}
    >
      {@result.title}
      <div class="badge badge-secondary badge-sm">{Common.humanize_status(@result.status)}</div>
    </LiveRedirect>
    <div class="text-xs">
      Submitted to
      <LiveRedirect
        to={Routes.studio_shop_path(Endpoint, :show, @result.studio_handle)}
        class="font-bold hover:text-secondary"
      >{@result.studio_name}</LiveRedirect>
      by
      <LiveRedirect
        to={Routes.denizen_show_path(Endpoint, :show, @result.client_handle)}
        class="font-bold hover:text-secondary"
      >
        <img class="w-4 inline-block" src={Routes.static_path(Endpoint, "/images/kat-chibi.jpeg")}>
        {@result.client_handle}
      </LiveRedirect>
      {Timex.format!(@result.submitted_at, "{relative}", :relative)}.
    </div>
    """
  end
end
