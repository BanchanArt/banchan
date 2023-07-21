defmodule BanchanWeb.OfferingLive.Request do
  @moduledoc """
  Subpage for creating a new commission based on an offering type.
  """
  use BanchanWeb, :live_view

  alias Banchan.Commissions
  alias Banchan.Commissions.{Commission, LineItem}
  alias Banchan.Offerings
  alias Banchan.Uploads

  alias Surface.Components.Form

  import BanchanWeb.StudioLive.Helpers

  alias BanchanWeb.CommissionLive.Components.{AddonList, BalanceBox, OfferingBox, Summary}
  alias BanchanWeb.Components.Form.{Checkbox, QuillInput, Submit, TextInput, UploadInput}
  alias BanchanWeb.Components.{Layout, Markdown}
  alias BanchanWeb.Endpoint

  @impl true
  def handle_params(%{"offering_type" => offering_type} = params, _uri, socket) do
    socket = assign_studio_defaults(params, socket, false, true)

    offering =
      Offerings.get_offering_by_type!(
        socket.assigns.current_user,
        socket.assigns.studio,
        offering_type
      )

    terms = offering.terms || socket.assigns.studio.default_terms
    template = offering.template || socket.assigns.studio.default_template

    cond do
      is_nil(socket.assigns.current_user.confirmed_at) ->
        socket =
          put_flash(
            socket,
            :warning,
            "You must verify your email address before requesting a commission."
          )

        {:noreply,
         push_navigate(socket,
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
              sticky: option.default,
              multiple: option.multiple
            }
          end)

        currency = Offerings.offering_currency(offering)

        {:noreply,
         socket
         |> assign(
           changeset:
             Commission.creation_changeset(
               %Commission{
                 currency: currency
               },
               %{}
             ),
           currency: currency,
           line_items: default_items,
           offering: offering,
           template: template,
           terms: terms
         )
         |> allow_upload(:attachment,
           accept: :any,
           max_entries: 10,
           max_file_size: Application.fetch_env!(:banchan, :max_attachment_size)
         )}

      true ->
        socket =
          put_flash(
            socket,
            :error,
            "This commission offering is currently unavailable."
          )

        {:noreply,
         push_navigate(socket,
           to: Routes.studio_shop_path(Endpoint, :show, socket.assigns.studio.handle)
         )}
    end
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
    tos_ok =
      if is_nil(socket.assigns.terms) do
        "true"
      else
        Map.get(commission, "tos_ok", "false")
      end

    changeset =
      %Commission{
        currency: socket.assigns.currency
      }
      |> Commission.creation_changeset(commission |> Map.put("tos_ok", tos_ok))
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
        description: option.description,
        multiple: option.multiple
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

  def handle_event("increase_item", %{"value" => idx}, socket) do
    update_line_item_count(idx, +1, socket)
  end

  def handle_event("decrease_item", %{"value" => idx}, socket) do
    update_line_item_count(idx, -1, socket)
  end

  @impl true
  # credo:disable-for-next-line Credo.Check.Refactor.CyclomaticComplexity
  def handle_event("submit", %{"commission" => commission}, socket) do
    tos_ok =
      if is_nil(socket.assigns.terms) do
        "true"
      else
        Map.get(commission, "tos_ok", "false")
      end

    attachments =
      consume_uploaded_entries(socket, :attachment, fn %{path: path}, entry ->
        {:ok,
         Uploads.save_file!(
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
           commission |> Map.put("tos_ok", tos_ok)
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

      {:error, :disabled} ->
        socket = put_flash(socket, :error, "You can't do that because your account is disabled.")

        {:noreply,
         push_navigate(socket,
           to: Routes.home_path(Endpoint, :index)
         )}

      {:error, :blocked} ->
        socket =
          put_flash(socket, :error, "You are not allowed to create commissions from this studio.")

        {:noreply,
         push_navigate(socket,
           to: Routes.home_path(Endpoint, :index)
         )}

      {:error, :studio_archived} ->
        socket =
          put_flash(
            socket,
            :error,
            "This offering's studio has been archived and will no longer accept new proposals."
          )

        {:noreply,
         push_navigate(socket,
           to: Routes.studio_shop_path(Endpoint, :show, socket.assigns.studio.handle)
         )}

      {:error, :offering_archived} ->
        socket =
          put_flash(
            socket,
            :error,
            "This offering has been archived and will no longer accept new proposals."
          )

        {:noreply,
         push_navigate(socket,
           to: Routes.studio_shop_path(Endpoint, :show, socket.assigns.studio.handle)
         )}

      {:error, :offering_closed} ->
        socket =
          put_flash(
            socket,
            :error,
            "This offering has been closed and will no longer accept new proposals."
          )

        {:noreply,
         push_navigate(socket,
           to: Routes.studio_shop_path(Endpoint, :show, socket.assigns.studio.handle)
         )}

      {:error, :not_confirmed} ->
        socket =
          put_flash(
            socket,
            :error,
            "You must confirm your account before you can request a commission."
          )

        {:noreply,
         push_navigate(socket,
           to:
             Routes.offering_show_path(
               Endpoint,
               :show,
               socket.assigns.studio.handle,
               socket.assigns.offering.type
             )
         )}

      {:error, :no_slots_available} ->
        socket = put_flash(socket, :error, "No more slots are available for this commission.")

        {:noreply,
         push_navigate(socket,
           to: Routes.studio_shop_path(Endpoint, :show, socket.assigns.studio.handle)
         )}

      {:error, :no_proposals_available} ->
        socket =
          put_flash(
            socket,
            :error,
            "New commissions of this kind are temporarily unavailable due to high request volume."
          )

        {:noreply,
         push_navigate(socket,
           to: Routes.studio_shop_path(Endpoint, :show, socket.assigns.studio.handle)
         )}
    end
  end

  def handle_info(%{event: "follower_count_changed", payload: new_count}, socket) do
    {:noreply, socket |> assign(followers: new_count)}
  end

  defp update_line_item_count(idx, delta, socket) do
    {idx, ""} = Integer.parse(idx)
    line_item = Enum.at(socket.assigns.line_items, idx)
    new_count = line_item.count + delta

    cond do
      new_count > 0 ->
        line_item = Map.put(line_item, :count, new_count)
        line_items = List.replace_at(socket.assigns.line_items, idx, line_item)
        {:noreply, assign(socket, line_items: line_items)}

      new_count <= 0 && !line_item.sticky ->
        {:noreply, assign(socket, line_items: List.delete_at(socket.assigns.line_items, idx))}

      true ->
        {:noreply, socket}
    end
  end

  @impl true
  def render(assigns) do
    ~F"""
    <Layout flashes={@flash}>
      <h1 class="text-2xl font-bold">Request a Commission</h1>
      <div class="divider" />
      <div class="flex flex-col space-y-2 md:container md:mx-auto p-2">
        <Form for={@changeset} change="change" submit="submit">
          <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div class="flex flex-col md:order-2 rounded-lg bg-base-200 p-4 shadow-lg">
              <OfferingBox offering={@offering} class="rounded-box hover:bg-base-200 p-2 transition-all" />
              <div class="divider" />
              <div class="font-medium text-sm opacity-50">Cart</div>
              <Summary
                allow_edits
                remove_item="remove_item"
                increase_item="increase_item"
                decrease_item="decrease_item"
                line_items={@line_items}
              />
              <div class="divider" />
              <BalanceBox id="balance-box" line_items={@line_items} />
              {#if Enum.any?(@offering.options, &(!&1.default))}
                <div class="flex flex-col gap-2">
                  <div class="w-full mt-2 border-t-2 border-content opacity-10" />
                  <div class="w-full mb-2 border-t-2 border-content opacity-10" />
                </div>
                <div class="px-2 font-medium text-sm opacity-50">Add-ons</div>
                <AddonList id="addon-list" offering={@offering} line_items={@line_items} add_item="add_item" />
              {/if}
            </div>
            <div class="divider md:hidden" />
            <div class="flex flex-col md:col-span-2 md:order-1 gap-4">
              <TextInput
                name={:title}
                show_label={false}
                class="w-full"
                opts={required: true, placeholder: "A Brief Title"}
              />
              <QuillInput
                id="initial-message"
                name={:description}
                show_label={false}
                class="w-full"
                upload={@uploads.attachment}
                cancel_upload="cancel_upload"
                opts={
                  required: true,
                  value: Map.get(@changeset.changes, :description, @template)
                }
              />
              {#if !is_nil(@terms)}
                <div class="pt-2">
                  <h3 class="py-4 font-bold text-xl">Commission Terms and Conditions</h3>
                  <div class="p-2 max-h-60 overflow-auto">
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
              {/if}
              <div class="p-2">
                <Submit changeset={@changeset} />
              </div>
            </div>
          </div>
        </Form>
      </div>
    </Layout>
    """
  end
end
