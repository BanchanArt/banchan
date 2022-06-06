defmodule BanchanWeb.CommissionLive.Components.CommissionRow do
  @moduledoc """
  Component for displaying dashboard result rows.
  """
  use BanchanWeb, :component

  alias Banchan.Commissions.Common

  alias Surface.Components.LivePatch

  alias BanchanWeb.Components.Avatar

  prop result, :struct, required: true
  prop highlight, :boolean, default: false

  def render(assigns) do
    commission_url =
      Routes.commission_path(
        Endpoint,
        :show,
        assigns.result.commission.public_id
      )

    ~F"""
    <li class={bordered: @highlight}>
      <LivePatch to={commission_url}>
        <div class="py-2 px-4">
          <div class="text-xl">
            {@result.commission.title}
            <div class="badge badge-secondary badge-sm">{Common.humanize_status(@result.commission.status)}</div>
            {#if @result.archived}
              <div class="badge badge-warning badge-sm">Archived</div>
            {/if}
          </div>
          <div class="text-xs text-left">
            <div class="inline">
              <div class="self-center inline">
                Submitted to
                <div class="inline font-bold">{@result.studio.name}</div>
                by
              </div>
              <div class="self-center inline">
                <Avatar link={false} user={@result.client} class="w-2.5" />
              </div>
              <div class="inline">
                <strong title={@result.client.handle} class="font-bold">{@result.client.handle}</strong>.
              </div>
              <div>
                Updated {Timex.format!(@result.updated_at, "{relative}", :relative)}.
              </div>
            </div>
          </div>
        </div>
      </LivePatch>
    </li>
    """
  end
end
