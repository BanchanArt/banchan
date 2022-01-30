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

  alias BanchanWeb.Components.{Button, Card}
  alias BanchanWeb.Components.Form.{Checkbox, Submit, TextArea, TextInput}
  alias BanchanWeb.Endpoint
  alias BanchanWeb.StudioLive.Components.Commissions.Attachments
  import BanchanWeb.StudioLive.Helpers

  @impl true
  def mount(%{"offering_type" => offering_type} = params, session, socket) do
    socket = assign_defaults(session, socket, true)
    socket = assign_studio_defaults(params, socket, false)
    offering = Offerings.get_offering_by_type!(offering_type)
    terms = HtmlSanitizeEx.markdown_html(Earmark.as_html!(offering.terms || ""))

    if offering.open do
      {:ok,
       assign(socket,
         changeset: Commission.changeset(%Commission{}, %{}),
         offering: offering,
         terms: terms
       )}
    else
      # TODO: Maybe show this on this page itself?
      socket =
        put_flash(
          socket,
          :error,
          "This commission offering is currently closed. Please try signing up for notifications for when it opens instead."
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

    line_item =
      %LineItem{option: option}
      |> LineItem.changeset(%{
        amount: option.price,
        name: option.name,
        description: option.description
      })

    line_items = Map.get(socket.assigns.changeset.changes, :line_items, []) ++ [line_item]

    changeset =
      socket.assigns.changeset
      |> Map.put(:changes, %{line_items: line_items})

    {:noreply, assign(socket, changeset: changeset)}
  end

  @impl true
  def handle_event("remove_option", %{"value" => idx}, socket) do
    {idx, ""} = Integer.parse(idx)

    line_items =
      Map.get(socket.assigns.changeset.changes, :line_items, [])
      |> List.delete_at(idx)

    changeset =
      socket.assigns.changeset
      |> Map.put(:changes, %{line_items: line_items})

    {:noreply, assign(socket, changeset: changeset)}
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
      <div class="grid grid-cols-5 gap-4">
        <div class="col-span-3">
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

        <div class="col-span-2 col-end-13 shadow-lg p-6">
          <div id="sidebar">
            <div class="block sidebar-box">
              <Card>
                <:header>Summary</:header>
                <ul class="divide-y">
                  <li class="container p-4">
                    <div class="float-right">
                      <span class="tag is-medium is-success">
                        {to_string(@offering.base_price || "No")}
                      </span>
                      <span class="tag is-medium">
                        Base Price
                      </span>
                    </div>
                    <div class="offering-name">
                      {@offering.name}
                    </div>
                    <div>{@offering.description}</div>
                  </li>
                  {#for {line_item, idx} <- Enum.with_index(Map.get(@changeset.changes, :line_items, []))}
                    <li>
                      <span>{to_string(line_item.changes.amount)}</span>
                      <span>{line_item.changes.name}</span>
                      <Button click="remove_option" value={idx}>Remove</Button>
                    </li>
                  {/for}
                </ul>
                <hr>
                <h5>Estimated Total</h5>
                <p>{Money.to_string(
                    Enum.reduce(
                      Map.get(@changeset.changes, :line_items, []),
                      # TODO: Using :USD here is a bad idea for later, but idk how to do it better yet.
                      @offering.base_price || Money.new(0, :USD),
                      fn item, acc -> Money.add(acc, item.changes.amount) end
                    )
                  )}</p>
                {#if Enum.any?(@offering.options)}
                  <hr>
                  <h5>Additional Options</h5>
                  <ul>
                    {#for {option, idx} <- Enum.with_index(@offering.options)}
                      <li>
                        <span>{to_string(option.price)}</span>
                        <span>{option.name}</span>
                        <Button click="add_option" value={idx}>Add</Button>
                      </li>
                    {/for}
                  </ul>
                {/if}
              </Card>
            </div>
            <div class="block sidebar-box">
              <Attachments id="commission-attachments" />
            </div>
          </div>
        </div>
      </div>
    </StudioLayout>
    """
  end
end
