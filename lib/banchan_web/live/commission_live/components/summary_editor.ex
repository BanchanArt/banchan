defmodule BanchanWeb.CommissionLive.Components.SummaryEditor do
  @moduledoc """
  This is a LiveComponent version of the Summary component that can handle
  summary state for an existing Commission.
  """
  use BanchanWeb, :live_component

  alias Banchan.Commissions
  alias Banchan.Commissions.LineItem
  alias Banchan.Repo
  alias Banchan.Utils

  alias BanchanWeb.CommissionLive.Components.Summary
  alias BanchanWeb.Components.Modal

  prop commission, :struct, required: true
  prop current_user, :struct, required: true
  prop current_user_member?, :boolean, required: true
  prop allow_edits, :boolean, required: true

  data studio, :struct
  data custom_changeset, :struct
  data deposited, :struct
  data open_custom, :boolean, default: false
  data loaded, :boolean, default: false

  def update(assigns, socket) do
    current_comm = Map.get(socket.assigns, :commission)
    new_comm = Map.get(assigns, :commission)
    socket = socket |> assign(assigns)

    custom_changeset =
      if socket.assigns.allow_edits do
        %LineItem{} |> LineItem.custom_changeset(%{})
      else
        nil
      end

    if socket.assigns.loaded do
      {:ok, socket |> assign(custom_changeset: custom_changeset)}
    else
      socket =
        if current_comm && (!new_comm || current_comm.public_id != new_comm.public_id) do
          socket |> assign(loaded: false)
        else
          socket
        end

      deposited =
        Commissions.deposited_amount(
          socket.assigns.current_user,
          socket.assigns.commission,
          socket.assigns.current_user_member?
        )

      studio = (socket.assigns.commission |> Repo.preload(:studio)).studio

      {:ok,
       socket
       |> assign(
         studio: studio,
         custom_changeset: custom_changeset,
         deposited: deposited,
         loaded: true
       )}
    end
  end

  def handle_info(%{event: "event_updated", payload: event}, socket) do
    if event.invoice do
      deposited =
        Commissions.deposited_amount(
          socket.assigns.current_user,
          socket.assigns.commission,
          socket.assigns.current_user_member?
        )

      {:noreply, socket |> assign(deposited: deposited)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("add_item", %{"value" => idx}, socket) do
    {idx, ""} = Integer.parse(idx)

    commission = socket.assigns.commission

    option =
      if commission.offering do
        {:ok, option} = Enum.fetch(commission.offering.options, idx)
        option
      else
        %{
          # TODO: fill this out?
        }
      end

    if !socket.assigns.allow_edits ||
         (!option.multiple &&
            Enum.any?(commission.line_items, &(&1.option && &1.option.id == option.id))) do
      # Deny the change. This shouldn't happen unless there's a bug, or
      # someone is trying to send us Shenanigans data.
      {:noreply, socket}
    else
      {:ok, {_commission, _events}} =
        Commissions.add_line_item(
          socket.assigns.current_user,
          commission,
          option,
          socket.assigns.current_user_member?
        )

      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("remove_item", %{"value" => idx}, socket) do
    {idx, ""} = Integer.parse(idx)
    line_item = Enum.at(socket.assigns.commission.line_items, idx)

    if socket.assigns.allow_edits && line_item && !line_item.sticky do
      {:ok, {_commission, _events}} =
        Commissions.remove_line_item(
          socket.assigns.current_user,
          socket.assigns.commission,
          line_item,
          socket.assigns.current_user_member?
        )

      {:noreply, socket}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("open_custom_modal", _, socket) do
    Modal.show(socket.assigns.id <> "_custom_modal")
    {:noreply, socket}
  end

  @impl true
  def handle_event("close_custom_modal", _, socket) do
    Modal.hide(socket.assigns.id <> "_custom_modal")
    {:noreply, socket}
  end

  @impl true
  def handle_event(
        "change_custom",
        %{
          "line_item" => %{
            "name" => name,
            "description" => description,
            "amount" => amount,
            "currency" => currency
          }
        },
        socket
      ) do
    changeset =
      %LineItem{}
      |> LineItem.custom_changeset(%{
        name: name,
        description: description,
        amount: Utils.moneyfy(amount, currency)
      })
      |> Map.put(:action, :insert)

    {:noreply, socket |> assign(:custom_changeset, changeset)}
  end

  @impl true
  def handle_event(
        "submit_custom",
        %{
          "line_item" => %{
            "name" => name,
            "description" => description,
            "amount" => amount,
            "currency" => currency
          }
        },
        socket
      ) do
    commission = socket.assigns.commission

    if socket.assigns.allow_edits do
      {:ok, {_commission, _events}} =
        Commissions.add_line_item(
          socket.assigns.current_user,
          commission,
          %{
            name: name,
            description: description,
            amount: Utils.moneyfy(amount, currency)
          },
          socket.assigns.current_user_member?
        )

      Modal.hide(socket.assigns.id <> "_custom_modal")

      {:noreply,
       assign(socket,
         custom_changeset: %LineItem{} |> LineItem.custom_changeset(%{})
       )}
    else
      # Deny the change. This shouldn't happen unless there's a bug, or
      # someone is trying to send us Shenanigans data.
      {:noreply, socket}
    end
  end

  def render(assigns) do
    ~F"""
    <Summary
      line_items={@commission.line_items}
      offering={@commission.offering}
      allow_edits={@allow_edits}
      add_item="add_item"
      remove_item="remove_item"
      custom_changeset={@custom_changeset}
      custom_modal_id={@id <> "_custom_modal"}
      open_custom_modal="open_custom_modal"
      close_custom_modal="close_custom_modal"
      change_custom="change_custom"
      submit_custom="submit_custom"
      deposited={@deposited}
      studio={@studio}
    />
    """
  end
end
