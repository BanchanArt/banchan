defmodule BanchanWeb.DashboardLive.Components.DashboardResult do
  @moduledoc """
  Component for displaying dashboard result rows.
  """
  use BanchanWeb, :component

  alias Banchan.Commissions.Common

  alias Surface.Components.LiveRedirect

  alias BanchanWeb.Components.{Avatar, UserHandle}

  prop result, :struct, required: true

  def render(assigns) do
    commission_url =
      Routes.studio_commissions_timeline_path(
        Endpoint,
        :show,
        assigns.result.studio.handle,
        assigns.result.commission.public_id
      )

    ~F"""
    <div class="relative">
      <LiveRedirect class="md:hidden absolute w-full h-full inset-0" to={commission_url} />
      <div class="py-2 px-4">
        <LiveRedirect class="text-2xl hover:text-secondary" to={commission_url}>
          {@result.commission.title}
          <div class="badge badge-secondary badge-sm">{Common.humanize_status(@result.commission.status)}</div>
        </LiveRedirect>
        <div class="text-sm text-left">
          <div class="inline-flex items-baseline space-x-0.5 flex-wrap">
            <span class="self-center">
              Submitted to
              <LiveRedirect
                to={Routes.studio_shop_path(Endpoint, :show, @result.studio.handle)}
                class="font-bold hover:text-secondary"
              >{@result.studio.name}</LiveRedirect>
              by
            </span>
            <div class="self-center">
              <Avatar user={@result.client} class="w-4" />
            </div>
            <UserHandle user={@result.client} />
            <span>
              {Timex.format!(@result.commission.inserted_at, "{relative}", :relative)}.
            </span>
            <div class="float-right">
              Updated {Timex.format!(@result.updated_at, "{relative}", :relative)}.
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
