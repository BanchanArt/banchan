defmodule BanchanWeb.StudioLive.Commissions.New do
  @moduledoc """
  Subpage for creating a new commission based on an offering type.
  """
  use BanchanWeb, :surface_view

  import Ecto.Changeset

  alias Banchan.Commissions
  alias Banchan.Commissions.{Commission, LineItem}
  alias Banchan.Offerings

  alias BanchanWeb.StudioLive.Components.StudioLayout

  alias Surface.Components.Form

  alias BanchanWeb.Components.{Button, Card}
  alias BanchanWeb.Components.Form.{Checkbox, Submit, TextArea, TextInput}
  alias BanchanWeb.Endpoint
  alias BanchanWeb.StudioLive.Components.Commissions.Attachments
  import BanchanWeb.StudioLive.Helpers

  @impl true
  def mount(%{"offering_type" => offering_type} = params, session, socket) do
    socket = assign_defaults(session, socket, true)
    socket = assign_studio_defaults(params, socket, false)
    offering = Offerings.get_offering_by_type!(offering_type, socket.assigns.current_user_member?)
    terms = HtmlSanitizeEx.markdown_html(Earmark.as_html!(offering.terms || ""))

    if offering.open do
      default_items =
        offering.options
        |> Enum.filter(& &1.default)
        |> Enum.map(fn option ->
          %LineItem{option: option}
          |> LineItem.changeset(%{
            amount: option.price,
            name: option.name,
            description: option.description,
            sticky: option.sticky
          })
        end)

      {:ok,
       assign(socket,
         changeset:
           Commission.changeset(%Commission{}, %{})
           |> put_assoc(:line_items, default_items),
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
      |> Map.put(:changes, %{
        line_items: Map.get(socket.assigns.changeset.changes, :line_items, [])
      })
      |> Map.put(:action, :update)

    socket = assign(socket, changeset: changeset)
    {:noreply, socket}
  end

  @impl true
  def handle_event("add_option", %{"value" => idx}, socket) do
    {idx, ""} = Integer.parse(idx)
    {:ok, option} = Enum.fetch(socket.assigns.offering.options, idx)

    current_line_items = fetch_field!(socket.assigns.changeset, :line_items)

    if !option.multiple && Enum.any?(current_line_items, &(&1.option.id == option.id)) do
      # Deny the change. This shouldn't happen unless there's a bug, or
      # someone is trying to send us Shenanigans data.
      {:noreply, socket}
    else
      line_item =
        %LineItem{option: option}
        |> LineItem.changeset(%{
          amount: option.price,
          name: option.name,
          description: option.description
        })

      line_items = current_line_items ++ [line_item]

      changeset =
        socket.assigns.changeset
        |> put_assoc(:line_items, line_items)

      {:noreply, assign(socket, changeset: changeset)}
    end
  end

  @impl true
  def handle_event("remove_option", %{"value" => idx}, socket) do
    {idx, ""} = Integer.parse(idx)
    line_items = Map.get(socket.assigns.changeset.changes, :line_items, [])
    line_item = Enum.at(line_items, idx)

    if line_item && !fetch_field!(line_item, :sticky) do
      changeset =
        socket.assigns.changeset
        |> Map.put(:changes, %{line_items: List.delete_at(line_items, idx)})

      {:noreply, assign(socket, changeset: changeset)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("submit", %{"commission" => commission}, socket) do
    commission =
      Map.put(
        commission,
        "line_items",
        Enum.map(Map.get(socket.assigns.changeset.changes, :line_items, []), & &1.changes)
      )

    case Commissions.create_commission(
           socket.assigns.current_user,
           socket.assigns.studio,
           socket.assigns.offering,
           commission
         ) do
      {:ok, commission} ->
        {:noreply,
         redirect(socket,
           to:
             Routes.studio_commissions_show_path(
               Endpoint,
               :show,
               socket.assigns.studio.handle,
               commission.public_id
             )
         )}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
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
          <div class="p-6">
            <h1 class="text-2xl">{@offering.name}</h1>
            <h2 class="text-xl">{@offering.description}</h2>
            <Form for={@changeset} change="change" submit="submit">
              <div class="block">
                <TextInput name={:title} opts={required: true, placeholder: "A Brief Title"} />
                <TextArea name={:description} opts={required: true, placeholder: "Here's what I'd like..."} />
              </div>
              <div class="content block">
                <h3>Terms and Conditions</h3>
                <p><strong>These Terms might vary between commission type.</strong></p>
                <div>{raw(@terms)}</div>
              </div>
              <Checkbox name={:tos_ok} opts={required: true}>
                I have read and agree to {@studio.name}'s <a href="#">Terms of Service</a>.
              </Checkbox>
              <Submit changeset={@changeset} />
            </Form>
          </div>
        </div>
        <div class="col-span-2 col-end-13 p-6">
          <div id="sidebar">
            <div class="block sidebar-box">
              <Card>
                <:header>Summary</:header>
                <ul class="divide-y">
                  {#for {line_item, idx} <- Enum.with_index(Map.get(@changeset.changes, :line_items, []))}
                    <li>
                      <span>{to_string(fetch_field!(line_item, :amount))}</span>
                      <span>{fetch_field!(line_item, :name)}</span>
                      {#if !fetch_field!(line_item, :sticky)}
                        <Button click="remove_option" value={idx}>Remove</Button>
                      {/if}
                    </li>
                  {/for}
                </ul>
                <hr>
                <h5>Estimated Total</h5>
                <p>{Money.to_string(
                    Enum.reduce(
                      fetch_field!(@changeset, :line_items),
                      # TODO: Using :USD here is a bad idea for later, but idk how to do it better yet.
                      Money.new(0, :USD),
                      fn item, acc -> Money.add(acc, item.amount) end
                    )
                  )}</p>
                {#if Enum.any?(@offering.options)}
                  <hr>
                  <h5>Additional Options</h5>
                  <ul>
                    {#for {option, idx} <- Enum.with_index(@offering.options)}
                      {#if option.multiple || !Enum.any?(fetch_field!(@changeset, :line_items), &(&1.option.id == option.id))}
                        <li>
                          <span>{to_string(option.price)}</span>
                          <span>{option.name}</span>
                          <Button click="add_option" value={idx}>Add</Button>
                        </li>
                      {/if}
                    {/for}
                  </ul>
                {/if}
              </Card>
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
