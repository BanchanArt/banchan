defmodule BanchanWeb.WorkLive.Work do
  @moduledoc """
  Editor/creator for Works. Lets you change the title and description of a Work,
  as well as manage its WorkUploads.
  """
  use BanchanWeb, :live_view

  import BanchanWeb.StudioLive.Helpers

  alias Banchan.Commissions
  alias Banchan.Offerings
  alias Banchan.Repo
  alias Banchan.Uploads
  alias Banchan.Works
  alias Banchan.Works.{Work, WorkUpload}

  alias Surface.Components.{
    Form,
    LiveFileInput,
    LivePatch,
    LiveRedirect
  }

  alias Surface.Components.Form.{ErrorTag, Field}

  alias BanchanWeb.Components.{
    Icon,
    Layout,
    RichText,
    Tag,
    WorkGallery
  }

  alias BanchanWeb.Components.Form.{
    Checkbox,
    ComboBox,
    QuillInput,
    Submit,
    TagsInput,
    TextInput,
    UploadInput
  }

  alias BanchanWeb.WorkLive.Components.WorkUploads

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> allow_upload(:uploads,
       accept: :any,
       max_entries: 10,
       max_file_size: Uploads.max_upload_size()
     )}
  end

  @impl true
  def handle_params(%{"work_id" => work_id} = params, _url, socket) do
    socket = assign_studio_defaults(params, socket, false, true)

    work =
      Works.get_work_by_public_id_if_allowed!(
        socket.assigns.studio,
        work_id,
        socket.assigns.current_user
      )

    socket =
      if socket.assigns.live_action == :edit do
        studio = socket.assigns.studio |> Repo.preload(:offerings)

        work = %{
          work
          | offering_type:
              case Enum.find(studio.offerings, &(&1.id == work.offering_id)) do
                nil -> nil
                offering -> offering.type
              end
        }

        assign(socket, studio: studio, work: work)
      else
        assign(socket, work: work)
      end

    work = socket.assigns.work

    changeset =
      if socket.assigns.live_action == :edit do
        Work.changeset(work, %{})
      end

    socket =
      if Works.first_previewable_upload(work) do
        socket
        |> assign(
          page_image:
            ~p"/studios/#{work.studio.handle}/works/#{work.public_id}/upload/#{Works.first_previewable_upload(work).upload_id}/preview"
        )
      else
        socket
      end

    {:noreply,
     socket
     |> assign(
       changeset: changeset,
       can_download?: Works.can_download_uploads?(socket.assigns.current_user, work),
       work_uploads: work.uploads |> Enum.map(&{:existing, &1}),
       related:
         Works.list_works(
           current_user: socket.assigns.current_user,
           order_by: :featured,
           related_to: work,
           page_size: 6
         ),
       page_title: work.title,
       page_description: HtmlSanitizeEx.strip_tags(work.description)
     )}
  end

  def handle_params(params, _url, socket) do
    socket = assign_studio_defaults(params, socket, true, true)

    work = %Work{} |> Repo.preload([:studio, uploads: [:upload]])

    changeset = Work.changeset(work, %{})

    commission =
      !is_nil(params["commission"]) &&
        Commissions.get_commission!(params["commission"], socket.assigns.current_user)

    offering =
      if commission && !is_nil(commission.offering_id) do
        commission = Repo.preload(commission, :offering)
        commission.offering
      else
        !is_nil(params["offering"]) &&
          Offerings.get_offering_by_type!(
            socket.assigns.current_user,
            socket.assigns.studio,
            params["offering"]
          )
      end

    socket = assign(socket, studio: socket.assigns.studio |> Repo.preload([:offerings]))

    {:noreply,
     socket
     |> assign(
       work: work,
       can_download?: false,
       changeset: changeset,
       work_uploads: work.uploads,
       commission: commission || nil,
       offering: offering || nil,
       related: [],
       page_title: "Create new Work",
       page_description: "Create a new Work to showcase your art."
     )}
  end

  @impl true
  def handle_event("change", %{"_target" => ["uploads"]}, socket) do
    uploads = socket.assigns.uploads

    {:noreply,
     Enum.reduce(uploads.uploads.entries, socket, fn entry, socket ->
       case upload_errors(uploads.uploads, entry) do
         [f | _] ->
           socket
           |> cancel_upload(:uploads, entry.ref)
           |> put_flash(
             :error,
             "File `#{entry.client_name}` upload failed: #{UploadInput.error_to_string(f)}"
           )

         [] ->
           socket
       end
     end)}
  end

  def handle_event("change", %{"work" => work}, socket) do
    uploads =
      socket.assigns.work_uploads
      |> Enum.with_index()
      |> Enum.map(fn {{ty, data}, index} ->
        if ty == :live do
          %WorkUpload{}
          |> WorkUpload.changeset(%{"index" => index, "ref" => data.ref, "comment" => ""})
        else
          data
          |> WorkUpload.changeset(%{"index" => index})
        end
      end)

    changeset =
      Work.changeset(socket.assigns.work, Map.put(work, "uploads", uploads))
      |> Map.put(:action, if(is_nil(socket.assigns.work.id), do: :insert, else: :update))

    {:noreply, assign(socket, changeset: changeset)}
  end

  def handle_event("submit", %{"work" => work}, socket)
      when is_nil(socket.assigns.work.id) do
    uploads =
      consume_uploaded_entries(socket, :uploads, fn %{path: path}, entry ->
        {:ok,
         {entry.ref,
          Uploads.save_file!(
            socket.assigns.current_user,
            path,
            entry.client_type,
            entry.client_name
          )}}
      end)

    offering =
      case work["offering_type"] do
        nil -> nil
        ty -> Enum.find(socket.assigns.studio.offerings, &(&1.type == ty))
      end

    Works.new_work(
      socket.assigns.current_user,
      socket.assigns.studio,
      work,
      uploads:
        socket.assigns.work_uploads
        |> Enum.map(fn {ty, data} ->
          if ty == :live do
            Enum.find_value(uploads, fn {ref, upload} ->
              if ref == data.ref, do: upload
            end)
          else
            data.upload
          end
        end),
      commission: socket.assigns.commission,
      offering: offering
    )
    |> case do
      {:ok, work} ->
        {:noreply,
         redirect(socket, to: ~p"/studios/#{socket.assigns.studio.handle}/works/#{work.public_id}")}

      {:error, bad_changeset} ->
        {:noreply, assign(socket, changeset: bad_changeset)}
    end
  end

  def handle_event("submit", %{"work" => work}, socket) do
    uploads =
      consume_uploaded_entries(socket, :uploads, fn %{path: path}, entry ->
        {:ok,
         {entry.ref,
          Uploads.save_file!(
            socket.assigns.current_user,
            path,
            entry.client_type,
            entry.client_name
          )}}
      end)

    offering =
      case work["offering_type"] do
        nil -> nil
        ty -> Enum.find(socket.assigns.studio.offerings, &(&1.type == ty))
      end

    Works.update_work(
      socket.assigns.current_user,
      socket.assigns.work,
      work,
      uploads:
        socket.assigns.work_uploads
        |> Enum.map(fn {ty, data} ->
          if ty == :live do
            Enum.find_value(uploads, fn {ref, upload} ->
              if ref == data.ref, do: upload
            end)
          else
            data.upload
          end
        end),
      offering: offering
    )
    |> case do
      {:ok, work} ->
        {:noreply,
         redirect(socket, to: ~p"/studios/#{socket.assigns.studio.handle}/works/#{work.public_id}")}

      {:error, bad_changeset} ->
        {:noreply, assign(socket, changeset: bad_changeset)}
    end
  end

  def handle_info({:updated_uploads, _, uploads}, socket) do
    uploads_param =
      uploads
      |> Enum.with_index()
      |> Enum.map(fn {{ty, data}, index} ->
        if ty == :live do
          %WorkUpload{}
          |> WorkUpload.changeset(%{"index" => index, "ref" => data.ref, "comment" => ""})
        else
          data
          |> WorkUpload.changeset(%{"index" => index})
        end
      end)

    changeset =
      Work.changeset(
        socket.assigns.work,
        socket.assigns.changeset.params |> Map.put("uploads", uploads_param)
      )
      |> Map.put(:action, if(is_nil(socket.assigns.work.id), do: :insert, else: :update))

    {:noreply,
     socket
     |> assign(work_uploads: uploads, changeset: changeset)}
  end

  @impl true
  def render(assigns) do
    ~F"""
    <Layout flashes={@flash}>
      <Form class="work-container" for={@changeset} change="change" submit="submit">
        <div class="work-info">
          <div class="title-wrapper">
            {#if is_nil(@changeset)}
              <h1 class="work-title">{@work.title}</h1>
            {#else}
              <div class="title-input-wrapper">
                <TextInput class="title-input" show_label={false} name={:title} opts={placeholder: "Title"} />
              </div>
            {/if}
          </div>
          <div class="source-info text-base grow">
            {#if !is_nil(@work.offering_id)}
              <LiveRedirect to={~p"/studios/#{@studio.handle}/offerings/#{@work.offering.type}"}>{@work.offering.name}</LiveRedirect>
            {/if}
            <span>
              by
            </span>
            <LiveRedirect to={~p"/studios/#{@studio.handle}"}>{@studio.name}</LiveRedirect>
          </div>
          <div class="flags-show">
            <span :if={@work.mature} title="Mature">M</span>
            <span :if={@work.private} title="Private">Private</span>
          </div>
        </div>
        <div class="preview-column">
          <WorkUploads
            id="work-uploads"
            send_updates_to={self()}
            studio={@studio}
            work={@work}
            editing={!is_nil(@changeset)}
            live_entries={@uploads.uploads.entries}
            work_uploads={@work_uploads}
            can_download?={@can_download?}
          />
          {#if !is_nil(@changeset)}
            <div class="upload-input" phx-drop-target={@uploads.uploads.ref}>
              <div>
                <span>Drop a file or click here to upload attachments</span>
                <Icon name="file-up" size="8" label="Upload attachment" />
              </div>
              <LiveFileInput upload={@uploads.uploads} />
            </div>
            <Field name={:uploads}>
              <ErrorTag class="help text-error" />
            </Field>
          {/if}
        </div>
        <div class="work-details">
          {#if is_nil(@changeset)}
            <h3 class="info-header">About This Work</h3>
            <RichText class="work-description info-field" content={@work.description} />
            {#if !Enum.empty?(@work.tags)}
              <ul class="work-tags">
                {#for tag <- @work.tags}
                  <li><Tag tag={tag} /></li>
                {/for}
              </ul>
            {/if}
            <p class="created-at">
              Created on
              <time datetime={@work.inserted_at |> Timex.to_datetime() |> Timex.format!("{RFC822}")}>
                {@work.inserted_at |> Timex.to_datetime() |> Timex.format!("{ISOdate}")}
                at
                {@work.inserted_at |> Timex.to_datetime() |> Timex.format!("{ISOtime}")}.
              </time>
            </p>
            {#if !is_nil(@work.commission_id) && !is_nil(@current_user) &&
                (@current_user_member? || @current_user.id == @work.client)}
              <h3 class="info-header">Source Commission</h3>
              <LiveRedirect
                class="commission-link"
                to={~p"/studios/#{@work.studio.handle}/commissions/#{@work.commission.public_id}"}
              >{@work.commission.title}</LiveRedirect>
            {/if}
            <LiveRedirect
              class="btn btn-success"
              to={if is_nil(@work.offering_id) do
                ~p"/studios/#{@work.studio.handle}"
              else
                ~p"/studios/#{@work.studio.handle}/offerings/#{@work.offering.type}"
              end}
            >
              Get Your Own!
            </LiveRedirect>
            {#if @current_user_member?}
              <LivePatch
                class="btn btn-success"
                to={~p"/studios/#{@studio.handle}/works/#{@work.public_id}/edit"}
              >Edit Work</LivePatch>
            {/if}
          {#else}
            <div class="work-form">
              <QuillInput id="work-description" label="Description" name={:description} />
              <TagsInput id="work-tags" label="Tags" name={:tags} />
              <div class="flags-form">
                <Checkbox label="Mature" name={:mature} />
                <Checkbox label="Private" name={:private} />
              </div>
              <ComboBox
                name={:offering_type}
                label="Offering"
                show_label
                class="offering-selector"
                options={[{"None", nil}] ++
                  (@studio.offerings
                   |> Enum.map(&{&1.name <> " - " <> HtmlSanitizeEx.strip_tags(&1.description), &1.type}))}
              />
              <Checkbox
                label="Showcase"
                name={:showcase}
                caption="Showcased works will be shown first in your studio portfolio and offering galleries. Think of it as pinning!"
              />
              {#if is_nil(@work.id)}
                <Submit label="Create Work" changeset={@changeset} />
              {#else}
                <div class="edit-buttons">
                  <Submit label="Save" changeset={@changeset} />
                  <LivePatch class="btn btn-error" to={~p"/studios/#{@studio.handle}/works/#{@work.public_id}"}>Cancel</LivePatch>
                </div>
              {/if}
            </div>
          {/if}
        </div>
      </Form>
      {#if !Enum.empty?(@related)}
        <div class="related">
          <h2 class="related-header">Related Works</h2>
          <div class="divider" />
          <WorkGallery works={@related} />
        </div>
      {/if}
    </Layout>
    """
  end
end
