defmodule BanchanWeb.StudioLive.Commissions.New do
  @moduledoc """
  Subpage for creating a new commission based on an offering type.
  """
  use BanchanWeb, :surface_view

  alias Banchan.Commissions
  alias Banchan.Commissions.{Commission, LineItem}
  alias Banchan.Offerings

  alias BanchanWeb.StudioLive.Components.StudioLayout

  alias Surface.Components.Form

  alias BanchanWeb.Components.Form.{Checkbox, Submit, TextArea, TextInput}
  alias BanchanWeb.Endpoint
  alias BanchanWeb.StudioLive.Components.Commissions.{Attachments, Summary}
  import BanchanWeb.StudioLive.Helpers

  @impl true
  def mount(%{"offering_type" => offering_type} = params, session, socket) do
    socket = assign_defaults(session, socket, true)
    socket = assign_studio_defaults(params, socket, false)
    offering = Offerings.get_offering_by_type!(offering_type, socket.assigns.current_user_member?)

    terms =
      HtmlSanitizeEx.markdown_html(
        Earmark.as_html!(offering.terms || socket.assigns.studio.default_terms || "")
      )

    if offering.open do
      default_items =
        offering.options
        |> Enum.filter(& &1.default)
        |> Enum.map(fn option ->
          %LineItem{
            option: option,
            amount: option.price || Money.new(0, :USD),
            name: option.name,
            description: option.description,
            sticky: option.sticky
          }
        end)

      {:ok,
       assign(socket,
         changeset: Commission.changeset(%Commission{}, %{}),
         line_items: default_items,
         offering: offering,
         terms: terms
       )}
    else
      # TODO: Maybe show this on this page itself?
      socket =
        put_flash(
          socket,
          :error,
          "This commission offering is currently unavailable."
        )

      {:ok,
       push_redirect(socket,
         to: Routes.studio_shop_path(Endpoint, :show, socket.assigns.studio.handle)
       )}
    end
  end

  @impl true
  def handle_event("change", %{"commission" => commission}, socket) do
    changeset =
      %Commission{}
      |> Commissions.change_commission(commission)
      |> Map.put(:action, :update)

    socket = assign(socket, changeset: changeset)
    {:noreply, socket}
  end

  @impl true
  def handle_event("add_item", %{"value" => idx}, socket) do
    {idx, ""} = Integer.parse(idx)
    {:ok, option} = Enum.fetch(socket.assigns.offering.options, idx)

    if !option.multiple && Enum.any?(socket.assigns.line_items, &(&1.option.id == option.id)) do
      # Deny the change. This shouldn't happen unless there's a bug, or
      # someone is trying to send us Shenanigans data.
      {:noreply, socket}
    else
      line_item = %LineItem{
        option: option,
        amount: option.price || Money.new(0, :USD),
        name: option.name,
        description: option.description
      }

      line_items = socket.assigns.line_items ++ [line_item]

      {:noreply, assign(socket, line_items: line_items)}
    end
  end

  @impl true
  def handle_event("remove_item", %{"value" => idx}, socket) do
    {idx, ""} = Integer.parse(idx)
    line_item = Enum.at(socket.assigns.line_items, idx)

    if line_item && !line_item.sticky do
      {:noreply, assign(socket, line_items: List.delete_at(socket.assigns.line_items, idx))}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("submit", %{"commission" => commission}, socket) do
    case Commissions.create_commission(
           socket.assigns.current_user,
           socket.assigns.studio,
           socket.assigns.offering,
           socket.assigns.line_items,
           commission
         ) do
      {:ok, created_commission} ->
        {:noreply,
         redirect(socket,
           to:
             Routes.studio_commissions_show_path(
               Endpoint,
               :show,
               socket.assigns.studio.handle,
               created_commission.public_id
             )
         )}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}

      {:error, :no_slots_available} ->
        socket = put_flash(socket, :error, "No more slots are available for this commission.")

        {:noreply,
         push_redirect(socket,
           to: Routes.studio_shop_path(Endpoint, :show, socket.assigns.studio.handle)
         )}

      {:error, :no_proposals_available} ->
        socket =
          put_flash(socket, :error, "New commissions of this kind are temporarily unavailable.")

        {:noreply,
         push_redirect(socket,
           to: Routes.studio_shop_path(Endpoint, :show, socket.assigns.studio.handle)
         )}
    end
  end

  @impl true
  def render(assigns) do
    ~F"""
    <StudioLayout
      current_user={@current_user}
      flashes={@flash}
      studio={@studio}
      current_user_member?={@current_user_member?}
      tab={:shop}
    >
      <div class="grid grid-cols-13 gap-4">
        <div class="col-span-10 shadow bg-base-200 text-base-content">
          <div class="p-6 space-y-2">
            <h1 class="text-2xl">{@offering.name}</h1>
            <h2 class="text-xl">{@offering.description}</h2>
            <Form for={@changeset} change="change" submit="submit">
              <div class="block space-y-4">
                <TextInput
                  name={:title}
                  show_label={false}
                  class="w-full"
                  opts={required: true, placeholder: "A Brief Title"}
                />
                <TextArea
                  name={:description}
                  show_label={false}
                  class="w-full"
                  opts={required: true, placeholder: "Here's what I'd like..."}
                />
              </div>
              <div class="content block">
                <h3>Terms and Conditions</h3>
                <p><strong>These Terms might vary between commission type.</strong></p>
                <div>{raw(@terms)}</div>
              </div>
              <Checkbox name={:tos_ok} opts={required: true}>
                I have read and agree to these Terms and Conditions.
              </Checkbox>
              <Submit changeset={@changeset} />
            </Form>
          </div>
        </div>
        <div class="col-span-2 col-end-13 p-6">
          <div id="sidebar">
            <div class="block sidebar-box">
              <Summary
                add_item="add_item"
                remove_item="remove_item"
                line_items={@line_items}
                offering={@offering}
              />
            </div>
            <div class="block sidebar-box pt-6">
              <Attachments id="commission-attachments" />
            </div>
          </div>
        </div>
      </div>
    </StudioLayout>
    """
  end
end
