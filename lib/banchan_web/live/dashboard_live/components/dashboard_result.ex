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
    ~F"""
    <div>
      <LiveRedirect
        class="text-xl hover:text-secondary"
        to={Routes.studio_commissions_show_path(
          Endpoint,
          :show,
          @result.studio.handle,
          @result.commission.public_id
        )}
      >
        {@result.commission.title}
        <div class="badge badge-secondary badge-sm">{Common.humanize_status(@result.commission.status)}</div>
      </LiveRedirect>
      <div class="text-xs text-left">
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
    """
  end
end
