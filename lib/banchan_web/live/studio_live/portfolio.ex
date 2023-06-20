defmodule BanchanWeb.StudioLive.Portfolio do
  @moduledoc """
  Portfolio tab page for a studio.
  """
  use BanchanWeb, :live_view

  import BanchanWeb.StudioLive.Helpers

  alias Banchan.Studios
  alias Banchan.Uploads

  alias Surface.Components.Form

  alias BanchanWeb.Components.Form.{Submit, UploadInput}
  alias BanchanWeb.Components.MasonryGallery
  alias BanchanWeb.StudioLive.Components.StudioLayout

  @impl true
  def mount(params, _session, socket) do
    socket = assign_studio_defaults(params, socket, false, false)

    socket =
      socket
      |> assign(
        :portfolio_images,
        Studios.studio_portfolio_uploads(socket.assigns.studio) |> Enum.map(&{:existing, &1})
      )
      |> assign(
        :changeset,
        Studios.Studio.profile_changeset(socket.assigns.studio, %{})
      )

    socket =
      if socket.assigns.current_user_member? do
        socket
        |> allow_upload(:portfolio_images,
          accept: Uploads.supported_image_format_extensions(),
          max_entries: 40,
          max_file_size: Application.fetch_env!(:banchan, :max_attachment_size)
        )
      else
        socket
      end

    {:ok, socket}
  end

  def handle_info({:updated_gallery_images, _, images}, socket) do
    {:noreply,
     socket
     |> assign(portfolio_images: images)}
  end

  @impl true
  def handle_event("cancel_portfolio_upload", %{"ref" => ref}, socket) do
    {:noreply, socket |> cancel_upload(:portfolio_images, ref)}
  end

  @impl true
  def handle_event("change", _, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("submit", _, socket) do
    new_portfolio_uploads =
      consume_uploaded_entries(socket, :portfolio_images, fn %{path: path}, entry ->
        {:ok,
         {entry.ref,
          Studios.make_portfolio_image!(
            socket.assigns.current_user,
            path,
            socket.assigns.current_user_member?,
            entry.client_type,
            entry.client_name
          )}}
      end)

    portfolio_images =
      socket.assigns.portfolio_images
      |> Enum.map(fn {type, data} ->
        if type == :existing do
          data
        else
          Enum.find_value(new_portfolio_uploads, fn {ref, upload} ->
            if ref == data.ref do
              upload
            end
          end)
        end
      end)

    case Studios.update_portfolio(
           socket.assigns.current_user,
           socket.assigns.studio,
           portfolio_images
         ) do
      {:ok, _} ->
        {:noreply,
         socket
         |> assign(
           :portfolio_images,
           portfolio_images |> Enum.map(&{:existing, &1})
         )}

      {:error, _} ->
        {:noreply, socket |> put_flash(:error, "Could not update portfolio")}
    end
  end

  @impl true
  def render(assigns) do
    ~F"""
    <StudioLayout flashes={@flash} id="studio-layout" studio={@studio} tab={:portfolio}>
      {#if @current_user_member?}
        <div class="mx-auto py-2">
          <Form for={%{}} as={:portfolio} change="change" submit="submit">
            <div class="flex flex-row">
              <UploadInput
                label="Portfolio Images"
                upload={@uploads.portfolio_images}
                cancel="cancel_portfolio_upload"
                hide_list
              />
              <Submit label="Save" />
            </div>
          </Form>
        </div>
      {/if}
      <MasonryGallery
        id="portfolio-preview"
        class="py-2 rounded-lg w-full"
        send_updates_to={self()}
        images={@portfolio_images}
        editable={@current_user_member?}
        upload_type={:studio_portfolio_img}
        entries={(@current_user_member? && @uploads.portfolio_images.entries) || []}
      />
    </StudioLayout>
    """
  end
end
