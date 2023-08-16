defmodule BanchanWeb.CommissionLive.Components.CommissionRow do
  @moduledoc """
  Component for displaying dashboard result rows.
  """
  use BanchanWeb, :component

  alias Banchan.Commissions.Common

  alias Surface.Components.{LivePatch, LiveRedirect}

  alias BanchanWeb.Components.{Avatar, Icon, StatusBadge, UserHandle}

  prop studio, :struct, from_context: :studio
  prop result, :struct, required: true

  # credo:disable-for-next-line Credo.Check.Refactor.CyclomaticComplexity
  defp status_map(status) do
    case status do
      :submitted -> :neutral
      :accepted -> :info
      :in_progress -> :info
      :paused -> :info
      :waiting -> :warning
      :ready_for_review -> :warning
      :approved -> :success
      :rejected -> :error
      :withdrawn -> :error
    end
  end

  def render(assigns) do
    commission_url =
      if is_nil(assigns.studio) do
        ~p"/commissions/#{assigns.result.commission.public_id}"
      else
        ~p"/studios/#{assigns.studio.handle}/commissions/#{assigns.result.commission.public_id}"
      end

    ~F"""
    <li class="relative flex items-center justify-between p-4 transition-all bg-opacity-50 rounded-lg cursor-pointer gap-x-6 bg-base-100 hover:bg-opacity-100 border-base-content border-opacity-10 active:translate-y-0.5">
      <div class="min-w-0">
        <div class="flex items-center gap-x-3">
          <LivePatch to={commission_url}>
            <span class="absolute inset-x-0 bottom-0 -top-px" />
            <p class="font-semibold leading-6 text-md">{@result.commission.title}</p>
          </LivePatch>
          {#if @result.offering}
            <svg viewBox="0 0 2 2" class="h-0.5 w-0.5 fill-current">
              <circle cx="1" cy="1" r="1" />
            </svg>
            <LiveRedirect
              to={~p"/studios/#{@result.studio.handle}/offerings/#{@result.offering.type}"}
              class="text-sm opacity-75"
            >{@result.offering.name}</LiveRedirect>
          {/if}
          <StatusBadge
            class="status"
            label={Common.humanize_status(@result.commission.status)}
            status={status_map(@result.commission.status)}
          />
        </div>
        <div class="flex flex-wrap items-center mt-1 text-xs leading-5 gap-x-2">
          {#if is_nil(@studio)}
            <div class="self-center inline truncate whitespace-nowrap">
              <div class="inline font-bold">
                {#if @result.studio && is_nil(@result.studio.deleted_at)}
                  {@result.studio.name}
                {#else}
                  (Deleted Studio)
                {/if}
              </div>
            </div>
          {#else}
            <div class="self-center inline">
              <Avatar link={false} user={@result.client} class="w-2.5" />
            </div>
            <div class="inline">
              <UserHandle link={false} user={@result.client} />
            </div>
          {/if}
          <svg viewBox="0 0 2 2" class="h-0.5 w-0.5 fill-current">
            <circle cx="1" cy="1" r="1" />
          </svg>
          <p class="whitespace-nowrap">Submitted <time datetime={@result.commission.inserted_at |> Timex.to_datetime() |> Timex.format!("{RFC822}")}>{@result.commission.inserted_at |> Timex.to_datetime() |> Timex.format!("{relative}", :relative)}</time></p>
          <svg viewBox="0 0 2 2" class="h-0.5 w-0.5 fill-current">
            <circle cx="1" cy="1" r="1" />
          </svg>
          <p class="whitespace-nowrap">Updated <time datetime={@result.updated_at |> Timex.to_datetime() |> Timex.format!("{RFC822}")}>{@result.updated_at |> Timex.to_datetime() |> Timex.format!("{relative}", :relative)}</time></p>
        </div>
      </div>
      <div class="shrink-0">
        <Icon name="chevron-right" class="w-5 h-5 opacity-75" />
      </div>
    </li>
    """
  end
end
