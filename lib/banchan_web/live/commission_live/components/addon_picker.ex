defmodule BanchanWeb.CommissionLive.Components.AddonPicker do
  @moduledoc """
  Lets you add new options to a commission, based on what's still available.
  """
  use BanchanWeb, :live_component

  alias Banchan.Commissions
  alias Banchan.Commissions.LineItem
  alias Banchan.Utils

  alias BanchanWeb.CommissionLive.Components.AddonList

  prop current_user, :struct, from_context: :current_user
  prop current_user_member?, :boolean, from_context: :current_user_member?
  prop commission, :struct, from_context: :commission

  prop allow_edits, :boolean, default: false
  prop allow_custom, :boolean, default: false

  data custom_changeset, :struct

  def update(assigns, socket) do
    socket = socket |> assign(assigns)

    custom_changeset =
      if socket.assigns.allow_custom do
        %LineItem{} |> LineItem.custom_changeset(%{})
      else
        nil
      end

    {:ok, socket |> assign(custom_changeset: custom_changeset)}
  end

  def handle_event("add_item", %{"value" => idx}, socket) do
    {idx, ""} = Integer.parse(idx)

    commission = socket.assigns.commission

    option =
      if commission.offering do
        {:ok, option} = Enum.fetch(commission.offering.options, idx)
        option
      else
        %{}
      end

    if !socket.assigns.allow_edits ||
         (!option.multiple &&
            Enum.any?(commission.line_items, &(&1.option && &1.option.id == option.id))) do
      # Deny the change. This shouldn't happen unless there's a bug, or
      # someone is trying to send us Shenanigans data.
      {:noreply, socket}
    else
      Commissions.add_line_item(
        socket.assigns.current_user,
        commission,
        option,
        socket.assigns.current_user_member?
      )
      |> case do
        {:ok, {_comm, _events}} ->
          {:noreply, socket}

        {:error, :blocked} ->
          {:noreply,
           socket
           |> put_flash(:error, "You are blocked from further interaction with this studio.")
           |> push_navigate(
             to: Routes.commission_path(Endpoint, :show, socket.assigns.commission.public_id)
           )}
      end
    end
  end

  def handle_event(
        "change_custom",
        %{
          "line_item" => %{
            "name" => name,
            "description" => description,
            "amount" => amount
          }
        },
        socket
      ) do
    changeset =
      %LineItem{}
      |> LineItem.custom_changeset(%{
        name: name,
        description: description,
        amount: Utils.moneyfy(amount, Commissions.commission_currency(socket.assigns.commission))
      })
      |> Map.put(:action, :insert)

    {:noreply, socket |> assign(:custom_changeset, changeset)}
  end

  def handle_event(
        "submit_custom",
        %{
          "line_item" => %{
            "name" => name,
            "description" => description,
            "amount" => amount
          }
        },
        socket
      ) do
    commission = socket.assigns.commission

    if socket.assigns.allow_edits do
      Commissions.add_line_item(
        socket.assigns.current_user,
        commission,
        %{
          name: name,
          description: description,
          amount: Utils.moneyfy(amount, Commissions.commission_currency(commission))
        },
        socket.assigns.current_user_member?
      )
      |> case do
        {:ok, {_commission, _events}} ->
          AddonList.set_open_custom(socket.assigns.id <> "-custom-collapse", false)

          {:noreply,
           assign(socket,
             custom_changeset: %LineItem{} |> LineItem.custom_changeset(%{})
           )}

        {:error, :blocked} ->
          {:noreply,
           socket
           |> put_flash(:error, "You are blocked from further interaction with this studio.")
           |> push_navigate(
             to: Routes.commission_path(Endpoint, :show, socket.assigns.commission.public_id)
           )}
      end
    else
      # Deny the change. This shouldn't happen unless there's a bug, or
      # someone is trying to send us Shenanigans data.
      {:noreply, socket}
    end
  end

  def render(assigns) do
    ~F"""
    <bc-addon-picker>
      <AddonList
        id={@id <> "-addon-list"}
        offering={@commission.offering}
        line_items={@commission.line_items}
        custom_changeset={@custom_changeset}
        add_item="add_item"
        change_custom="change_custom"
        submit_custom="submit_custom"
      />
    </bc-addon-picker>
    """
  end
end
