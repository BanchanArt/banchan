defmodule BanchanWeb.StudioLive.Commissions.New do
  @moduledoc """
  Subpage for creating a new commission based on an offering type.
  """
  use BanchanWeb, :surface_view

  alias Banchan.Commissions
  alias Banchan.Commissions.{Commission, LineItem}
  alias Banchan.Offerings

  alias Surface.Components.Form

  import BanchanWeb.StudioLive.Helpers

  alias BanchanWeb.CommissionLive.Components.Summary
  alias BanchanWeb.Components.Form.{Checkbox, MarkdownInput, Submit, TextInput, UploadInput}
  alias BanchanWeb.Components.Markdown
  alias BanchanWeb.Endpoint
  alias BanchanWeb.StudioLive.Components.StudioLayout

  @impl true
  def mount(%{"offering_type" => offering_type} = params, _session, socket) do
    socket = assign_studio_defaults(params, socket, false, true)

    offering =
      Offerings.get_offering_by_type!(
        socket.assigns.studio,
        offering_type,
        socket.assigns.current_user_member?
      )

    terms = offering.terms || socket.assigns.studio.default_terms || ""
    template = offering.template || socket.assigns.studio.default_template

    cond do
      is_nil(socket.assigns.current_user.confirmed_at) ->
        socket =
          put_flash(
            socket,
            :warning,
            "You must verify your email address before requesting a commission."
          )

        {:ok,
         push_redirect(socket,
           to: Routes.studio_shop_path(Endpoint, :show, socket.assigns.studio.handle)
         )}

      offering.open ->
        default_items =
          offering.options
          |> Enum.filter(& &1.default)
          |> Enum.map(fn option ->
            %LineItem{
              option: option,
              amount: option.price,
              name: option.name,
              description: option.description,
              sticky: option.sticky
            }
          end)

        {:ok,
         socket
         |> assign(
           changeset: Commission.creation_changeset(%Commission{}, %{}),
           line_items: default_items,
           offering: offering,
           template: template,
           terms: terms
         )
         # TODO: move max file size somewhere configurable.
         # TODO: constrain :accept?
         |> allow_upload(:attachment,
           accept: :any,
           max_entries: 10,
           max_file_size: 25_000_000
         )}

      true ->
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
  def handle_params(_params, uri, socket) do
    {:noreply, socket |> assign(uri: uri)}
  end

  @impl true
  def handle_event("cancel_upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :attachment, ref)}
  end

  @impl true
  def handle_event("change", %{"_target" => ["attachment"]}, socket) do
    uploads = socket.assigns.uploads

    {:noreply,
     Enum.reduce(uploads.attachment.entries, socket, fn entry, socket ->
       case upload_errors(uploads.attachment, entry) do
         [f | _] ->
           socket
           |> cancel_upload(:attachment, entry.ref)
           |> put_flash(
             :error,
             "File `#{entry.client_name}` upload failed: #{UploadInput.error_to_string(f)}"
           )

         [] ->
           socket
       end
     end)}
  end

  @impl true
  def handle_event("change", %{"commission" => commission}, socket) do
    changeset =
      %Commission{}
      |> Commission.creation_changeset(commission)
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
        amount: option.price,
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
    attachments =
      consume_uploaded_entries(socket, :attachment, fn %{path: path}, entry ->
        {:ok,
         Commissions.make_attachment!(
           socket.assigns.current_user,
           path,
           entry.client_type,
           entry.client_name
         )}
      end)

    case Commissions.create_commission(
           socket.assigns.current_user,
           socket.assigns.studio,
           socket.assigns.offering,
           socket.assigns.line_items,
           attachments,
           commission
         ) do
      {:ok, created_commission} ->
        {:noreply,
         redirect(socket,
           to:
             Routes.commission_path(
               Endpoint,
               :show,
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

  def handle_info(%{event: "follower_count_changed", payload: new_count}, socket) do
    {:noreply, socket |> assign(followers: new_count)}
  end

  @impl true
  def render(assigns) do
    ~F"""
    <StudioLayout
      id="studio-layout"
      current_user={@current_user}
      flashes={@flash}
      studio={@studio}
      followers={@followers}
      current_user_member?={@current_user_member?}
      tab={:shop}
      uri={@uri}
    >
      <div class="flex flex-col space-y-2 md:container md:mx-auto p-2">
        <h1 class="text-3xl px-2">{@offering.name}</h1>
        <h2 class="text-xl px-2">{@offering.description}</h2>
        <Form for={@changeset} change="change" submit="submit">
          <div class="flex flex-col md:grid md:grid-cols-3 gap-4">
            <div class="md:order-1 md:col-span-2">
              <TextInput
                name={:title}
                show_label={false}
                class="w-full"
                opts={required: true, placeholder: "A Brief Title"}
              />
            </div>
            <div class="md:order-2 md:col-span-1 md:row-span-5">
              <Summary
                add_item="add_item"
                allow_edits
                remove_item="remove_item"
                line_items={@line_items}
                offering={@offering}
                studio={@studio}
              />
            </div>
            <div class="md:order-2 md:col-span-2 md:row-span-2">
              <MarkdownInput
                id="initial-message"
                name={:description}
                show_label={false}
                class="w-full h-96"
                height="384px"
                upload={@uploads.attachment}
                cancel_upload="cancel_upload"
                opts={
                  required: true,
                  placeholder: "Here's what I'd like...",
                  value: Map.get(@changeset.changes, :description, @template)
                }
              />
            </div>
            <div class="md:col-span-2 md:order-4 md:row-span-2">
              <div class="pt-2">
                <h3 class="py-4 font-bold text-xl">Commission Terms and Conditions</h3>
                <div class="p-2 border-2 rounded border-neutral max-h-60 overflow-auto">
                  <div class="p-2">
                    <Markdown content={@terms} />
                  </div>
                </div>
              </div>
              <div class="p-2">
                <Checkbox name={:tos_ok} opts={required: true}>
                  I have read and agree to these Terms.
                </Checkbox>
              </div>
              <div class="p-2">
                <Submit changeset={@changeset} />
              </div>
            </div>
          </div>
        </Form>
      </div>
    </StudioLayout>
    """
  end
end
