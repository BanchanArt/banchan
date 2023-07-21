defmodule BanchanWeb.CommissionLive.Components.SummaryEditor do
  @moduledoc """
  This is a LiveComponent version of the Summary component that can handle
  summary state for an existing Commission.
  """
  use BanchanWeb, :live_component

  alias Banchan.Commissions

  alias BanchanWeb.CommissionLive.Components.Summary

  prop commission, :struct, from_context: :commission
  prop current_user, :struct, from_context: :current_user
  prop current_user_member?, :boolean, from_context: :current_user_member?
  prop allow_edits, :boolean, required: true

  def handle_event("remove_item", %{"value" => idx}, socket) do
    {idx, ""} = Integer.parse(idx)
    line_item = Enum.at(socket.assigns.commission.line_items, idx)

    if socket.assigns.allow_edits && line_item && !line_item.sticky do
      Commissions.remove_line_item(
        socket.assigns.current_user,
        socket.assigns.commission,
        line_item,
        socket.assigns.current_user_member?
      )
      |> case do
        {:ok, {_commission, _events}} ->
          {:noreply, socket}

        {:error, :blocked} ->
          {:noreply,
           socket
           |> put_flash(:error, "You are blocked from further interaction with this studio.")
           |> push_navigate(
             to: Routes.commission_path(Endpoint, :show, socket.assigns.commission.public_id)
           )}
      end

      {:noreply, socket}
    else
      {:noreply, socket}
    end
  end

  def handle_event("increase_item", %{"value" => idx}, socket) do
    update_line_item_count(idx, +1, socket)
  end

  def handle_event("decrease_item", %{"value" => idx}, socket) do
    update_line_item_count(idx, -1, socket)
  end

  defp update_line_item_count(idx, delta, socket) do
    {idx, ""} = Integer.parse(idx)
    line_item = Enum.at(socket.assigns.commission.line_items, idx)

    if socket.assigns.allow_edits && line_item && !line_item.sticky do
      Commissions.update_line_item_count(
        socket.assigns.current_user,
        socket.assigns.commission,
        line_item,
        delta,
        socket.assigns.current_user_member?
      )
      |> case do
        {:ok, {_commission, _events}} ->
          {:noreply, socket}

        {:error, :blocked} ->
          {:noreply,
           socket
           |> put_flash(:error, "You are blocked from further interaction with this studio.")
           |> push_navigate(
             to: Routes.commission_path(Endpoint, :show, socket.assigns.commission.public_id)
           )}
      end

      {:noreply, socket}
    else
      {:noreply, socket}
    end
  end

  def render(assigns) do
    ~F"""
    <Summary
      line_items={@commission.line_items}
      allow_edits={@allow_edits}
      remove_item="remove_item"
      increase_item="increase_item"
      decrease_item="decrease_item"
    />
    """
  end
end
