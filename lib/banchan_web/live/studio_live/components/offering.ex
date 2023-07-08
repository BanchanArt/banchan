defmodule BanchanWeb.StudioLive.Components.Offering do
  @moduledoc """
  Component for creating and editing Offerings.
  """
  use BanchanWeb, :live_component

  import Slug

  alias Surface.Components.Form
  alias Surface.Components.Form.Inputs

  alias Banchan.Offerings
  alias Banchan.Offerings.{Offering, OfferingOption}
  alias Banchan.Uploads
  alias Banchan.Utils

  alias BanchanWeb.Components.{Button, Collapse, MasonryGallery, OfferingCard}

  alias BanchanWeb.Components.Form.{
    Checkbox,
    HiddenInput,
    MarkdownInput,
    Select,
    Submit,
    TagsInput,
    TextArea,
    TextInput,
    UploadInput
  }

  prop current_user, :struct, required: true
  prop current_user_member?, :boolean, required: true
  prop studio, :struct, required: true
  prop offering, :struct
  prop gallery_images, :any
  prop form, :form, from_context: {Form, :form}

  data changeset, :struct
  data uploads, :map
  data remove_card, :boolean, default: false

  def mount(socket) do
    {:ok,
     socket
     |> allow_upload(:card_image,
       accept: Uploads.supported_image_format_extensions(),
       max_entries: 1,
       max_file_size: Application.fetch_env!(:banchan, :max_attachment_size)
     )
     |> allow_upload(:gallery_images,
       accept: Uploads.supported_image_format_extensions(),
       max_entries: 10,
       max_file_size: Application.fetch_env!(:banchan, :max_attachment_size)
     )}
  end

  # credo:disable-for-next-line Credo.Check.Refactor.CyclomaticComplexity
  def update(assigns, socket) do
    old_assigns = socket.assigns
    socket = socket |> assign(assigns)

    socket =
      socket
      |> assign(remove_card: false)
      |> assign(
        changeset:
          old_assigns[:changeset] ||
            Offering.changeset(
              socket.assigns.offering ||
                %Offering{
                  currency: socket.assigns.studio.default_currency,
                  options: [
                    %OfferingOption{
                      name: "Default Option 1",
                      description: "Base commission.",
                      price: Money.new(0, socket.assigns.studio.default_currency),
                      default: true,
                      sticky: true
                    }
                  ]
                },
              %{}
            )
      )

    socket =
      if is_nil(assigns[:gallery_images]) &&
           old_assigns[:gallery_images] == assigns[:gallery_images] do
        socket
      else
        # Cancel any live items that got removed.
        old_assigns[:gallery_images]
        |> Enum.filter(fn {type, data} ->
          type == :live &&
            !Enum.find(assigns[:gallery_images], fn {t, d} ->
              t == :live && data.ref == d.ref
            end)
        end)
        |> Enum.reduce(socket, fn {:live, entry}, socket ->
          socket |> cancel_upload(:gallery_images, entry.ref)
        end)
        |> assign(
          changeset:
            socket.assigns.changeset |> Ecto.Changeset.put_change(:gallery_imgs_changed, true)
        )
      end

    {:ok,
     socket
     |> assign(
       gallery_images:
         if socket.assigns.offering && is_nil(assigns[:gallery_images]) do
           Offerings.offering_gallery_uploads(socket.assigns.offering)
           |> Enum.map(&{:existing, &1})
         else
           assigns[:gallery_images] || []
         end
     )}
  end

  @impl true
  def handle_event("archive", _, %{assigns: %{changeset: %{data: data}}} = socket) do
    if data && data.id do
      {:ok, _} =
        Offerings.archive_offering(
          socket.assigns.current_user,
          %Offering{id: data.id}
        )

      {:noreply,
       redirect(socket,
         to: Routes.studio_shop_path(Endpoint, :show, socket.assigns.studio.handle)
       )}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("unarchive", _, %{assigns: %{changeset: %{data: data}}} = socket) do
    if data && data.id do
      {:ok, _} =
        Offerings.unarchive_offering(
          socket.assigns.current_user,
          %Offering{id: data.id}
        )

      {:noreply,
       redirect(socket,
         to: Routes.studio_shop_path(Endpoint, :show, socket.assigns.studio.handle)
       )}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("add_option", _, socket) do
    changeset = %OfferingOption{} |> OfferingOption.changeset(%{})
    options = Ecto.Changeset.fetch_field!(socket.assigns.changeset, :options) ++ [changeset]

    offering_changeset =
      socket.assigns.changeset
      |> Ecto.Changeset.put_assoc(:options, options)

    {:noreply, assign(socket, changeset: offering_changeset)}
  end

  @impl true
  def handle_event("remove_option", %{"value" => index}, socket) do
    {index, ""} = Integer.parse(index)
    options = Ecto.Changeset.fetch_field!(socket.assigns.changeset, :options)
    options = List.delete_at(options, index)

    offering_changeset =
      socket.assigns.changeset
      |> Ecto.Changeset.put_assoc(:options, options)

    {:noreply, assign(socket, changeset: offering_changeset)}
  end

  @impl true
  def handle_event("change", %{"offering" => offering, "_target" => target}, socket) do
    offering =
      if target == ["offering", "name"] do
        %{offering | "type" => slugify(offering["name"])}
      else
        offering
      end

    offering =
      if target == ["offering", "gallery_images"] do
        %{offering | "gallery_imgs_changed" => true}
      else
        offering
      end

    offering = moneyfy_offering(offering)

    changeset =
      (socket.assigns.offering || %Offering{})
      |> Offerings.change_offering(offering)
      |> Map.put(:action, :update)

    socket =
      socket
      |> assign(changeset: changeset)

    {:noreply, socket}
  end

  def handle_event("remove_card", _, socket) do
    {:noreply, assign(socket, remove_card: true)}
  end

  @impl true
  def handle_event("cancel_card_upload", %{"ref" => ref}, socket) do
    {:noreply, socket |> cancel_upload(:card_image, ref)}
  end

  @impl true
  def handle_event("cancel_gallery_upload", %{"ref" => ref}, socket) do
    {:noreply, socket |> cancel_upload(:gallery_images, ref)}
  end

  @impl true
  def handle_event("delete_offering", _, socket) do
    case Offerings.delete_offering(socket.assigns.current_user, socket.assigns.offering) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "Offering successfully deleted.")
         |> push_navigate(
           to: Routes.studio_shop_path(Endpoint, :show, socket.assigns.studio.handle)
         )}

      {:error, _} ->
        {:noreply,
         socket
         |> put_flash(
           :error,
           "An error occurred while trying to delete this offering. Wait a bit and try again."
         )
         |> push_navigate(
           to:
             Routes.studio_offerings_edit_path(
               Endpoint,
               :edit,
               socket.assigns.studio.handle,
               socket.assigns.offering.type
             )
         )}
    end
  end

  @impl true
  # credo:disable-for-next-line Credo.Check.Refactor.CyclomaticComplexity
  def handle_event("submit", %{"offering" => offering}, socket) do
    offering = moneyfy_offering(offering)

    card_image =
      consume_uploaded_entries(socket, :card_image, fn %{path: path}, entry ->
        {:ok,
         Offerings.make_card_image!(
           socket.assigns.current_user,
           socket.assigns.studio,
           path,
           entry.client_type,
           entry.client_name
         )}
      end)
      |> Enum.at(0)

    new_gallery_uploads =
      consume_uploaded_entries(socket, :gallery_images, fn %{path: path}, entry ->
        {:ok,
         {entry.ref,
          Offerings.make_gallery_image!(
            socket.assigns.current_user,
            socket.assigns.studio,
            path,
            entry.client_type,
            entry.client_name
          )}}
      end)

    gallery_images =
      socket.assigns.gallery_images
      |> Enum.map(fn {type, data} ->
        if type == :existing do
          data
        else
          Enum.find_value(new_gallery_uploads, fn {ref, upload} ->
            if ref == data.ref do
              upload
            end
          end)
        end
      end)

    case submit_offering(
           socket.assigns.current_user,
           socket.assigns.offering,
           Enum.into(offering, %{
             "card_img_id" => (card_image && card_image.id) || offering["card_image_id"]
           }),
           gallery_images,
           socket.assigns.studio
         ) do
      {:ok, offering} ->
        {:noreply,
         redirect(socket,
           to:
             Routes.offering_show_path(
               Endpoint,
               :show,
               socket.assigns.studio.handle,
               offering.type
             )
         )}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  defp submit_offering(actor, offering, attrs, gallery_images, studio)
       when is_nil(offering) do
    Offerings.new_offering(
      actor,
      studio,
      attrs,
      gallery_images
    )
  end

  defp submit_offering(actor, offering, attrs, gallery_images, _studio)
       when not is_nil(offering) do
    Offerings.update_offering(
      actor,
      offering,
      attrs,
      gallery_images
    )
  end

  defp moneyfy_offering(offering) do
    # *sigh*
    Map.update(offering, "options", [], fn options ->
      Map.values(options)
      |> Enum.with_index()
      |> Enum.map(fn {opt, idx} ->
        key = to_string(idx)

        opt =
          case Map.fetch(offering, "currency") do
            {:ok, currency} ->
              opt
              |> Map.update("price", "", &Utils.moneyfy(&1, currency))

            :error ->
              opt
          end

        {key, opt}
      end)
      |> Map.new()
    end)
  end

  def render(assigns) do
    ~F"""
    <Form
      for={@changeset}
      submit="submit"
      change="change"
      opts={autocomplete: "off", "phx-target": @myself}
    >
      <div class="flex flex-col gap-2">
        <TextInput
          name={:name}
          info="Name of the offering, as it should appear in the offering card."
          opts={required: true, phx_debounce: "200"}
        />
        <TextInput
          name={:type}
          info="Lowercase, no-spaces, limited characters. This is what will show up in the url and must be unique."
          opts={required: true}
        />
        <MarkdownInput
          id={@id <> "-description-input"}
          name={:description}
          info="Description of the offering, as it should appear when the offering is expanded."
          opts={required: true}
        />
        <TagsInput
          id={@id <> "-tags"}
          info="Type to search for existing tags. Press Enter or Tab to add the tag. You can make it whatever you want as long as it's 100 characters or shorter."
          name={:tags}
        />
        <Checkbox
          name={:open}
          label="Open"
          info="Open up this offering for new proposals. The offering will remain visible if closed."
        />
        <Checkbox
          name={:hidden}
          label="Hide"
          info="Hide this offering from the shop, search, and listings. You will still be able to link people to it."
        />
        {#if Application.get_env(:banchan, :mature_content_enabled?)}
          <Checkbox
            name={:mature}
            label="Mature"
            info="Mark this offering as mature content. Note: if you plan on doing mature/NSFW commissions through this offering, this MUST be checked."
          />
        {/if}
        <div class="divider" />
        <div>While Slots determines how many commissions you're willing to accept at a time, Max Proposals determines how many people can make a proposal at the same time.</div>
        <div>This is useful if you want to limit the number of commission requests you get at once. Accepted commissions do not count towards your Max Proposals, and proposed commissions do not count towards your Slots.
        </div>
        <div>Leave Max Proposals blank to make it unlimited.</div>
        <TextInput
          name={:max_proposals}
          info="Max proposals. Unlike slots, these are used as soon as someone makes a proposal. Use this setting to prevent your inbox from getting flooded with too many proposals. Leave blank for unlimited proposals."
        />
        <TextInput
          name={:slots}
          info="Max slots available. Slots are used up as you accept commissions. Leave blank for unlimited slots."
        />
        <div class="divider" />
        <h2 class="text-2xl">Card Image</h2>
        <div>You must have a card image in order for the offering to be listed on site search. Otherwise, you will only be able to link directly to it.</div>
        <div class="relative">
          {#if Enum.empty?(@uploads.card_image.entries) &&
              (@remove_card || !(@offering && @offering.card_img_id))}
            <HiddenInput name={:card_image_id} value={nil} />
          {#elseif !Enum.empty?(@uploads.card_image.entries)}
            <button
              type="button"
              phx-value-ref={(@uploads.card_image.entries |> Enum.at(0)).ref}
              class="btn btn-md btn-circle absolute left-2 top-2 z-20"
              :on-click="cancel_card_upload"
            >✕</button>
          {#else}
            <button
              type="button"
              class="btn btn-md btn-circle absolute left-2 top-2 z-20"
              :on-click="remove_card"
            >✕</button>
            <HiddenInput name={:card_image_id} value={@offering.card_img_id} />
          {/if}
          <OfferingCard
            name={Ecto.Changeset.get_field(@changeset, :name)}
            image={cond do
              Enum.empty?(@uploads.card_image.entries) &&
                  (@remove_card || !(@offering && @offering.card_img_id)) ->
                nil

              !Enum.empty?(@uploads.card_image.entries) ->
                Enum.at(@uploads.card_image.entries, 0)

              true ->
                @offering.card_img_id
            end}
            base_price={if is_nil(Ecto.Changeset.get_field(@changeset, :options)) ||
                 Enum.empty?(Ecto.Changeset.get_field(@changeset, :options)) do
              nil
            else
              Ecto.Changeset.get_field(@changeset, :options)
              |> Enum.filter(&(&1.default && &1.price))
              |> Enum.map(& &1.price)
              |> Enum.reduce(Money.new(0, Ecto.Changeset.fetch_field!(@changeset, :currency)), &Money.add/2)
            end}
            open?={Ecto.Changeset.get_field(@changeset, :open)}
            hidden?={Ecto.Changeset.get_field(@changeset, :hidden)}
            mature?={Ecto.Changeset.get_field(@changeset, :mature)}
            hover_grow?={false}
            total_slots={Ecto.Changeset.get_field(@changeset, :slots)}
            available_slots={Ecto.Changeset.get_field(@changeset, :slots)}
          />
        </div>
        <UploadInput
          label="Upload Card Image"
          upload={@uploads.card_image}
          cancel="cancel_card_upload"
          hide_list
        />
        <div class="divider" />
        <h3 class="text-2xl">Gallery Images</h3>
        <div>Gallery images will be shown on the offering's page, as example works. You can drag and drop them to reorder them.</div>
        <MasonryGallery
          id={@id <> "-gallery-preview"}
          class="py-2 rounded-lg"
          send_updates_to={self()}
          images={@gallery_images}
          editable
          upload_type={:offering_gallery_img}
          entries={@uploads.gallery_images.entries}
        />
        <UploadInput
          label="Upload Gallery Images"
          upload={@uploads.gallery_images}
          cancel="cancel_gallery_upload"
          hide_list
        />
        <div class="divider" />
        <h3 class="text-2xl">Options</h3>
        <div>
          Options are the items that will be available for clients to put in their "carts". The commission's Base Price is based on the default options.
        </div>
        <div>
          If you do not define any options, the Base Price will be displayed as "Inquire", and you will need to add custom options during the commission.
        </div>
        <ul class="flex flex-col gap-4 pt-4">
          <Inputs form={@form} for={:options} :let={index: index}>
            <li>
              <Collapse id={@id <> "-option-" <> "#{index}"} class="border-b-2">
                <:header>
                  <h3 class="text-xl">
                    {opt = Enum.at(Ecto.Changeset.fetch_field!(@changeset, :options), index)

                    (opt.name || "New Option") <>
                      if opt.price do
                        " - " <> Money.to_string(opt.price)
                      else
                        ""
                      end}
                  </h3>
                </:header>
                <TextInput name={:name} info="Name of the option." opts={required: true} />
                <TextArea name={:description} info="Description for the option." opts={required: true} />
                <div class="flex flex-row gap-2 items-center py-2">
                  <div class="flex flex-basis-1/4">
                    {Money.Currency.symbol(Ecto.Changeset.fetch_field!(@changeset, :currency))}
                  </div>
                  <div class="grow">
                    <TextInput name={:price} info="Quoted price for adding this option." show_label={false} />
                  </div>
                </div>
                <Checkbox
                  name={:multiple}
                  info="Allow multiple instances of this option at the same time."
                  label="Allow Multiple"
                />
                <Checkbox
                  name={:default}
                  info="Whether this option is added by default. Default options are also used to calculate your offering's base price."
                  label="Default"
                />
                {#if Ecto.Changeset.fetch_field!(@changeset, :options) |> Enum.at(0) |> then(& &1.default)}
                  <Checkbox
                    name={:sticky}
                    info="Sticky defaults can't be removed from the cart."
                    label="Sticky Default"
                  />
                {/if}
                <Button class="w-full btn-sm btn-error" value={index} click="remove_option">Remove</Button>
              </Collapse>
            </li>
          </Inputs>
          <li class="field">
            <div class="control">
              <Button class="w-full" click="add_option" label="Add Option" />
            </div>
          </li>
        </ul>
        <Select
          name={:currency}
          label="Option Currency"
          info="Currency to use for all options. Only one currency is allowed per offering."
          options={@studio.payment_currencies
          |> Enum.map(&{"#{to_string(&1)}#{Money.Currency.symbol(&1)}", &1})}
          opts={required: true}
        />
        <div class="divider" />
        <Collapse class="border-b-2 pb-2" id={@id <> "-terms-collapse"}>
          <:header>
            <h3 class="text-2xl">Terms and Template</h3>
          </:header>
          <MarkdownInput
            id={@id <> "-tos"}
            name={:terms}
            info="Terms of service specific to this offering. Leave blank to use your studio's default terms."
          />
          <MarkdownInput
            id={@id <> "-template"}
            name={:template}
            info="Template that clients will see when they start filling out the commission request. Leave blank to use your studio's default template."
          />
        </Collapse>
        <div class="pt-4 flex flex-row">
          <Submit changeset={@changeset} label="Save" />
          {#if @changeset.data.id && is_nil(@changeset.data.archived_at)}
            <Button class="btn-error" click="archive" label="Archive" />
          {/if}
          {#if @changeset.data.id && @changeset.data.archived_at}
            <Button class="btn-error" click="unarchive" label="Unarchive" />
          {/if}
        </div>
        {#if @changeset.data.id}
          <Collapse id="delete-offering-collapse" class="w-full pt-4">
            <:header>
              <div class="font-semibold text-error">Delete</div>
            </:header>
            <div class="prose">
              <p>This operation <strong>can't be reversed</strong>.</p>
              <p>Deleting an offering will prevent you from being able to edit add-ons in existing commissions, and commissions made with this offering will not be able to link back to it.</p>
              <p>You will also not be able to create an offering with the same name for <strong>30 days</strong>. If you want to reuse this name, change the offering's type <i>before</i> deletion.</p>
              <p>If you simply want to prevent new commissions from being created for this offering, please consider archiving it instead.</p>
              <p>Are you sure you want to delete this offering?</p>
            </div>
            <Button click="delete_offering" class="w-full btn-error" label="Confirm" />
          </Collapse>
        {/if}
      </div>
    </Form>
    """
  end
end
