defmodule BanchanWeb.StudioLive.Components.Offering do
  @moduledoc """
  Component for creating and editing Offerings.
  """
  use BanchanWeb, :live_component

  import Slug

  alias Surface.Components.Form
  alias Surface.Components.Form.Input.InputContext
  alias Surface.Components.Form.Inputs

  alias Banchan.Offerings
  alias Banchan.Offerings.{Offering, OfferingOption}
  alias Banchan.Utils

  alias BanchanWeb.Components.{Button, MasonryGallery}

  alias BanchanWeb.Components.Form.{
    Checkbox,
    MarkdownInput,
    Submit,
    TextArea,
    TextInput,
    UploadInput
  }

  prop current_user, :struct, required: true
  prop current_user_member?, :boolean, required: true
  prop studio, :struct, required: true
  prop offering, :struct
  prop gallery_images, :any

  data changeset, :struct
  data uploads, :map

  def mount(socket) do
    {:ok,
     socket
     |> allow_upload(:card_image,
       # TODO: Be less restrictive here
       accept: ~w(.jpg .jpeg .png),
       max_entries: 1,
       max_file_size: 10_000_000
     )
     |> allow_upload(:gallery_images,
       # TODO: Be less restrictive here
       accept: ~w(.jpg .jpeg .png),
       max_entries: 10,
       max_file_size: 10_000_000
     )}
  end

  def update(assigns, socket) do
    socket = socket |> assign(assigns)

    {:ok,
     socket
     |> assign(changeset: Offering.changeset(socket.assigns.offering || %Offering{}, %{}))
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
        Offerings.archive_offering(%Offering{id: data.id}, socket.assigns.current_user_member?)

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

  @impl true
  def handle_event("cancel_card_upload", %{"ref" => ref}, socket) do
    {:noreply, socket |> cancel_upload(:card_image, ref)}
  end

  @impl true
  def handle_event("cancel_gallery_upload", %{"ref" => ref}, socket) do
    {:noreply, socket |> cancel_upload(:gallery_images, ref)}
  end

  @impl true
  def handle_event("submit", %{"offering" => offering}, socket) do
    offering = moneyfy_offering(offering)

    card_images =
      consume_uploaded_entries(socket, :card_image, fn %{path: path}, _entry ->
        {:ok,
         Offerings.make_card_image!(
           socket.assigns.current_user,
           path,
           socket.assigns.current_user_member?
         )}
      end)

    new_gallery_uploads =
      consume_uploaded_entries(socket, :gallery_images, fn %{path: path}, entry ->
        {:ok,
         {entry.ref, Offerings.make_gallery_image!(
           socket.assigns.current_user,
           path,
           socket.assigns.current_user_member?
         )}}
      end)

    gallery_images = socket.assigns.gallery_images
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
           socket.assigns.offering,
           offering,
           Enum.at(card_images, 0),
           gallery_images,
           socket.assigns.studio,
           socket.assigns.current_user_member?
         ) do
      {:ok, _offering} ->
        {:noreply,
         redirect(socket,
           to: Routes.studio_shop_path(Endpoint, :show, socket.assigns.studio.handle)
         )}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  defp submit_offering(offering, attrs, card_image, gallery_images, studio, current_user_member?)
       when is_nil(offering) do
    Offerings.new_offering(
      studio,
      current_user_member?,
      attrs,
      card_image,
      gallery_images
    )
  end

  defp submit_offering(offering, attrs, card_image, gallery_images, _studio, current_user_member?)
       when not is_nil(offering) do
    Offerings.update_offering(
      offering,
      current_user_member?,
      attrs,
      card_image,
      gallery_images
    )
  end

  defp moneyfy_offering(offering) do
    # *sigh*
    Map.update(offering, "options", [], fn options ->
      Map.new(
        Enum.map(Enum.with_index(Map.values(options)), fn {opt, idx} ->
          {to_string(idx), Map.update(opt, "price", "", &Utils.moneyfy/1)}
        end)
      )
    end)
  end

  def render(assigns) do
    ~F"""
    <Form
      for={@changeset}
      change="change"
      opts={
        autocomplete: "off",
        phx_target: @myself,
        phx_submit: "submit"
      }
    >
      <TextInput
        name={:name}
        info="Name of the offering, as it should appear in the offering card."
        opts={required: true}
      />
      <TextInput
        name={:type}
        info="Lowercase, no-spaces, limited characters. This is what will show up in the url and must be unique."
        opts={required: true}
      />
      <TextArea
        name={:description}
        info="Description of the offering, as it should appear in the offering card."
        opts={required: true}
      />
      <div class="relative pb-video">
        {#if Enum.empty?(@uploads.card_image.entries) && !(@offering && @offering.card_img_id)}
          <img
            class="absolute h-full w-full object-cover"
            src={Routes.static_path(Endpoint, "/images/640x360.png")}
          />
        {#elseif !Enum.empty?(@uploads.card_image.entries)}
          {Phoenix.LiveView.Helpers.live_img_preview(Enum.at(@uploads.card_image.entries, 0),
            class: "absolute h-full w-full object-cover"
          )}
        {#else}
          <img
            class="absolute h-full w-full object-cover"
            src={Routes.public_image_path(Endpoint, :image, @offering.card_img_id)}
          />
        {/if}
      </div>
      <UploadInput label="Card Image" upload={@uploads.card_image} cancel="cancel_card_upload" />
      <div tabindex="0" class="collapse">
        <input phx-update="ignore" type="checkbox">
        <div class="collapse-title text-xl rounded-lg border border-primary">
          Gallery Images
        </div>
        <div class="collapse-content">
          <MasonryGallery
            id="gallery-preview"
            send_updates_to={self()}
            images={@gallery_images}
            entries={@uploads.gallery_images.entries}
          />
          <UploadInput
            label="Gallery Images"
            upload={@uploads.gallery_images}
            cancel="cancel_gallery_upload"
          />
        </div>
      </div>
      <TextInput
        name={:slots}
        info="Max slots available. Slots are used up as you accept commissions. Leave blank for unlimited slots."
      />
      <TextInput
        name={:max_proposals}
        info="Max proposals. Unlike slots, these are used as soon as someone makes a proposal. Use this setting to prevent your inbox from getting flooded with too many proposals. Leave blank for unlimited proposals."
      />
      <Checkbox
        name={:open}
        label="Open"
        info="Open up this offering for new proposals. The offering will remain visible if closed."
      />
      <Checkbox
        name={:hidden}
        label="Hide from Shop"
        info="Hide this offering from the shop. You will still be able to link people to it."
      />
      <h3 class="text-2xl">Options</h3>
      <div class="divider" />
      <ul class="flex flex-col gap-2">
        <InputContext :let={form: form}>
          <Inputs form={form} for={:options} :let={index: index}>
            <li tabindex="0" class="collapse">
              <input phx-update="ignore" type="checkbox">
              <div class="collapse-title text-xl rounded-lg border border-primary">
                {opt = Enum.at(Ecto.Changeset.fetch_field!(@changeset, :options), index)
                (opt.name || "New Option") <> " - " <> Money.to_string(opt.price || Money.new(0, :USD))}
              </div>
              <div class="collapse-content">
                <TextInput name={:name} info="Name of the option." opts={required: true} />
                <TextArea name={:description} info="Description for the option." opts={required: true} />
                <TextInput name={:price} info="Quoted price for adding this option." opts={required: true} />
                <Checkbox
                  name={:multiple}
                  info="Allow multiple instances of this option at the same time."
                  label="Allow Multiple"
                />
                <Checkbox name={:sticky} info="Once this option is added, it can't be removed." label="Sticky" />
                <Checkbox
                  name={:default}
                  info="Whether this option is added by default. Default options are also used to calculate your offering's base price."
                  label="Default"
                />
                <Button class="w-full btn-sm btn-error" value={index} click="remove_option">Remove</Button>
              </div>
            </li>
          </Inputs>
        </InputContext>
        <li class="field">
          <div class="control">
            <Button class="w-full" click="add_option" label="Add Option" />
          </div>
        </li>
      </ul>
      <div class="divider" />
      <div tabindex="0" class="collapse">
        <input phx-update="ignore" type="checkbox">
        <h3 class="collapse-title rounded-lg border border-primary text-2xl">Terms and Template</h3>
        <div class="collapse-content">
          <MarkdownInput
            id="tos"
            name={:terms}
            info="Terms of service specific to this offering. Leave blank to use your studio's default terms."
          />
          <MarkdownInput
            id="template"
            name={:template}
            info="Template that clients will see when they start filling out the commission request. Leave blank to use your studio's default template."
          />
        </div>
      </div>
      <div class="divider" />
      <div class="flex flex-row">
        <Submit label="Save" />
        {#if @changeset.data.id}
          <Button class="btn-error" click="archive" label="Archive" />
        {/if}
      </div>
    </Form>
    """
  end
end
