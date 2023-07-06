defmodule BanchanWeb.CommissionLive.Components.StatusItem do
  @moduledoc """
  Individual item in the status dropdown.
  """
  use BanchanWeb, :component

  alias Banchan.Commissions
  alias BanchanWeb.Components.DropdownItem

  import Banchan.Commissions, only: [status_transition_allowed?: 4]

  prop status, :atom, required: true
  prop click, :event, required: true
  prop current_user, :struct, from_context: :current_user
  prop current_user_member?, :boolean, from_context: :current_user_member?
  prop commission, :struct, from_context: :commission

  def render(assigns) do
    ~F"""
    {#if status_transition_allowed?(
        @current_user_member?,
        @current_user.id == @commission.client_id,
        @commission.status,
        @status
      )}
      <DropdownItem>
        <button :on-click={@click} value={@status}>
          <div class="flex flex-col items-start">
            <span>{Commissions.Common.humanize_status(@status)}</span>
            <span class="text-xs text-base-content text-left opacity-50">
              {Commissions.Common.status_description(@status)}
            </span>
          </div>
        </button>
      </DropdownItem>
    {/if}
    """
  end
end
