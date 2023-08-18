defmodule BanchanWeb.OfferingLive.Request do
  @moduledoc """
  Subpage for creating a new commission based on an offering type.
  """
  use BanchanWeb, :live_view

  alias Banchan.Commissions
  alias Banchan.Commissions.{Commission, LineItem}
  alias Banchan.Offerings
  alias Banchan.Uploads

  alias Surface.Components.{Form, LiveRedirect}

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

    available_slots = Offerings.offering_available_slots(offering)

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
           available_slots: available_slots,
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
             if socket.assigns.current_user_member? do
               ~p"/studios/#{socket.assigns.studio.handle}/commissions/#{created_commission.public_id}"
             else
               ~p"/commissions/#{created_commission.public_id}"
             end
         )}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}

      {:error, :disabled} ->
        socket = put_flash(socket, :error, "You can't do that because your account is disabled.")

        {:noreply,
         redirect(socket,
           to: ~p"/"
         )}

      {:error, :blocked} ->
        socket =
          put_flash(socket, :error, "You are not allowed to create commissions from this studio.")

        {:noreply,
         redirect(socket,
           to: ~p"/"
         )}

      {:error, :studio_archived} ->
        socket =
          put_flash(
            socket,
            :error,
            "This offering's studio has been archived and will no longer accept new proposals."
          )

        {:noreply,
         redirect(socket,
           to: ~p"/"
         )}

      {:error, :offering_archived} ->
        socket =
          put_flash(
            socket,
            :error,
            "This offering has been archived and will no longer accept new proposals."
          )

        {:noreply,
         redirect(socket,
           to: ~p"/studios/#{socket.assigns.studio.handle}"
         )}

      {:error, :offering_closed} ->
        socket =
          put_flash(
            socket,
            :error,
            "This offering has been closed and will no longer accept new proposals."
          )

        {:noreply,
         redirect(socket,
           to:
             ~p"/studios/#{socket.assigns.studio.handle}/offerings/#{socket.assigns.offering.type}"
         )}

      {:error, :not_confirmed} ->
        socket =
          put_flash(
            socket,
            :error,
            "You must confirm your account before you can request a commission."
          )

        {:noreply,
         redirect(socket,
           to:
             ~p"/studios/#{socket.assigns.studio.handle}/offerings/#{socket.assigns.offering.type}"
         )}

      {:error, :no_slots_available} ->
        socket = put_flash(socket, :error, "No more slots are available for this commission.")

        {:noreply,
         redirect(socket,
           to:
             ~p"/studios/#{socket.assigns.studio.handle}/offerings/#{socket.assigns.offering.type}"
         )}

      {:error, :no_proposals_available} ->
        socket =
          put_flash(
            socket,
            :error,
            "New commissions of this kind are temporarily unavailable due to high request volume."
          )

        {:noreply,
         redirect(socket,
           to:
             ~p"/studios/#{socket.assigns.studio.handle}/offerings/#{socket.assigns.offering.type}"
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
      <div class="w-full mx-auto max-w-7xl">
        <div class="grid grid-cols-1 gap-4 px-4 py-2">
          <h1 class="text-2xl font-bold">Request a Commission</h1>
          <div class="m-0 divider h-fit" />
        </div>
        <div class="flex flex-col px-4 py-2 space-y-2 md:container md:mx-auto">
          <Form for={@changeset} change="change" submit="submit">
            <div class="grid grid-cols-1 gap-4 md:grid-cols-3">
              <div class="flex flex-col gap-4 rounded-lg md:order-1 bg-base-200">
                <div class="grid grid-cols-1 gap-2">
                  <OfferingBox
                    offering={@offering}
                    available_slots={@available_slots}
                    class="transition-all rounded-box hover:bg-base-200"
                  />
                  <span class="text-sm"><span class="opacity-75">By
                    </span><LiveRedirect
                      class="font-semibold opacity-75 hover:opacity-100 hover:underline"
                      to={~p"/studios/#{@studio.handle}"}
                    >{@studio.name}</LiveRedirect>
                  </span>
                </div>
                <div class="grid grid-cols-1 gap-2">
                  <div class="text-sm font-medium opacity-50">Cart</div>
                  <div class="grid w-full grid-cols-1 gap-4 p-4 border rounded-lg border-base-content border-opacity-10 bg-base-100">
                    <Summary
                      allow_edits
                      remove_item="remove_item"
                      increase_item="increase_item"
                      decrease_item="decrease_item"
                      line_items={@line_items}
                    />
                    <div class="m-0 divider h-fit" />
                    <BalanceBox id="balance-box" line_items={@line_items} />
                  </div>
                </div>
                <div class="m-0 divider h-fit" />
                {#if Enum.any?(@offering.options, &(!&1.default))}
                  <div class="text-sm font-medium opacity-50">Add-ons</div>
                  <div class="grid w-full grid-cols-1 gap-4 p-4 border rounded-lg border-base-content border-opacity-10 bg-base-100">
                    <AddonList
                      id="addon-list"
                      offering={@offering}
                      line_items={@line_items}
                      allow_edits
                      add_item="add_item"
                    />
                  </div>
                {/if}
              </div>
              <div class="divider md:hidden" />
              <div class="flex flex-col gap-4 md:col-span-2 md:order-2">
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
                    <h3 class="py-4 text-sm font-medium opacity-75">Commission Terms and Conditions</h3>
                    <div class="grid grid-cols-1 gap-4 p-4 overflow-auto border rounded-lg bg-base-100 border-base-content border-opacity-10 max-h-60">
                      <Markdown content={@terms} />
                      <div class="m-0 divider h-fit" />
                      <Checkbox name={:tos_ok} opts={required: true}>
                        I have read and agree to these Terms.
                      </Checkbox>
                    </div>
                  </div>
                {/if}
                <div class="py-2">
                  <Submit changeset={@changeset} />
                </div>
              </div>
            </div>
          </Form>
        </div>
      </div>
    </Layout>
    """
  end
end
