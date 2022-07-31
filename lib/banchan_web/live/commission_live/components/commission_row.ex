defmodule BanchanWeb.CommissionLive.Components.CommissionRow do
  @moduledoc """
  Component for displaying dashboard result rows.
  """
  use BanchanWeb, :component

  alias Banchan.Commissions.Common

  alias Surface.Components.LivePatch

  alias BanchanWeb.Components.{Avatar, UserHandle}

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
        <div>
          <div class="text-2xl flex flex-row gap-2 flex-wrap items-center">
            <span>{@result.commission.title}</span>
            <div class="badge badge-primary badge-sm cursor-default">{Common.humanize_status(@result.commission.status)}</div>
            {#if @result.archived}
              <div class="badge badge-warning badge-sm cursor-default">Archived</div>
            {/if}
          </div>
          <div class="text-sm text-left">
            <div class="inline">
              <div class="self-center inline">
                Submitted to
                <div class="inline font-bold">
                  {#if @result.studio && is_nil(@result.studio.deleted_at)}
                    {@result.studio.name}
                  {#else}
                    (Deleted Studio)
                  {/if}
                </div>
                by
              </div>
              <div class="self-center inline">
                <Avatar link={false} user={@result.client} class="w-2.5" />
              </div>
              <div class="inline">
                <UserHandle link={false} user={@result.client} />
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
