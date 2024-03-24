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
    Tag
  }

  alias BanchanWeb.Components.Form.{
    Checkbox,
    FancySelect,
    QuillInput,
    Submit,
    TagsInput,
    TextInput
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
        work = %{work | offering_idx: case Enum.find_index(studio.offerings, &(&1.id == work.offering_id)) do
          nil -> nil
          idx -> to_string(idx + 1)
        end}
        assign(socket, studio: studio, work: work)
      else
        assign(socket, work: work)
      end

    work = socket.assigns.work

    changeset =
      if socket.assigns.live_action == :edit do
        Work.changeset(work, %{})
      end

    {:noreply,
     socket
     |> assign(
       changeset: changeset,
       can_download?: Works.can_download_uploads?(socket.assigns.current_user, work),
       work_uploads: work.uploads |> Enum.map(&{:existing, &1}),
       page_title: work.title,
       page_description: HtmlSanitizeEx.strip_tags(work.description),
       page_image:
         ~p"/studios/#{work.studio.handle}/works/#{work.public_id}/upload/#{Enum.at(work.uploads, 0).upload_id}/preview"
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

    socket = assign(socket, studio: socket.assigns.studio |> Repo.reload([:offerings]))

    {:noreply,
     socket
     |> assign(
       work: work,
       can_download?: false,
       changeset: changeset,
       work_uploads: work.uploads,
       commission: commission || nil,
       offering: offering || nil,
       page_title: "Create new Work",
       page_description: "Create a new Work to showcase your art."
     )}
  end

  @impl true
  def handle_event("change", %{"work" => work} = all, socket) do
    IO.inspect(all)
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

    idx = if !is_nil(work["offering_idx"]) do
      {idx, ""} = Integer.parse(work["offering_idx"])
      idx
    end

    offering = if !is_nil(idx) && idx > 0 do
      Enum.at(socket.assigns.studio.offerings, idx - 1)
    else
      socket.assigns.work.offering
    end

    Works.new_work(
      socket.assigns.current_user,
      socket.assigns.studio,
      work,
      uploads: socket.assigns.work_uploads
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

  def handle_event("submit", %{"work" => work, "offering_idx" => offering_idx}, socket) do
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

    idx = if !is_nil(offering_idx) do
      {idx, ""} = Integer.parse(offering_idx)
      idx
    end

    offering = if !is_nil(idx) && idx > 0 do
      Enum.at(socket.assigns.studio.offerings, idx - 1)
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
    <style>
      :global(.work-container) {
      @apply w-full p-4 mx-auto max-w-7xl grid grid-cols-1 md:grid-cols-3 gap-4;
      }

      .work-title, .title-input-wrapper {
      @apply w-full;
      }

      .work-title {
      @apply text-3xl font-bold;
      }

      .preview-column {
      @apply flex flex-col gap-4 md:col-span-2 md:row-span-2;
      }

      .work-details {
      @apply md:row-span-2 flex flex-col gap-2;
      }

      .title-wrapper {
      @apply flex flex-row items-center w-full;
      }

      .title-inputs {
      @apply flex flex-row items-center w-full gap-2;
      }

      .title-input-wrapper {
      @apply grow;
      }

      .title-input {
      @apply w-full text-3xl;
      }

      .work-form {
      @apply flex flex-col gap-2;
      }

      .work-form > .edit-buttons {
      @apply flex flex-row gap-2;
      }

      .work-form > .edit-buttons :deep(div) {
      @apply flex grow;
      }

      .work-form :deep(.btn) {
      @apply grow;
      }

      .work-info {
      @apply grid-cols-1 flex flex-col gap-2;
      }

      .info-header {
      @apply text-sm font-medium opacity-75;
      }

      .info-field {
      @apply p-4 border rounded-lg border-base-content border-opacity-10 bg-base-100;
      }

      .work-tags {
      @apply flex flex-row gap-2;
      }

      .flags-form {
      @apply flex flex-row gap-8;
      }

      .flags-show {
      @apply flex flex-row items-center gap-2;
      }

      .flags-show > span {
      @apply flex flex-row items-center px-1 py-px text-xs font-bold bg-opacity-75 border rounded-md bg-error text-error-content border-base-content border-opacity-10 cursor-pointer;
      }
      .source-info {
      @apply text-base grow;
      }

      .source-info > span {
      @apply opacity-75;
      }

      .source-info > :deep(a), .commission-link {
      @apply font-medium hover:link;
      }

      .upload-input {
      @apply relative flex flex-row items-center justify-center p-4 border-2 border-dashed rounded-lg cursor-pointer border-primary h-16;
      }

      .upload-input > div:first-child {
      @apply flex flex-row items-center justify-center gap-2 font-normal cursor-pointer w-full grow;
      }

      .upload-input > div:first-child > span {
      @apply cursor-pointer;
      }

      .upload-input > :deep(input) {
      @apply absolute w-full h-full opacity-0 cursor-pointer;
      }

      :root :deep(.offering-selector) {
      @apply flex flex-row items-center gap-4 btn btn-primary w-full;
      }

      :root :deep(.offering-selector) :deep(.button-label) {
        @apply grow text-left;
      }
    </style>

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
              <div class="work-tags">
                {#for tag <- @work.tags}
                  <Tag tag={tag} />
                {/for}
              </div>
            {/if}
            {#if !is_nil(@work.commission_id) && !is_nil(@current_user) &&
                (@current_user_member? || @current_user.id == @work.client)}
              <h3 class="info-header">Source Commission</h3>
              <LiveRedirect
                class="commission-link"
                to={~p"/studios/#{@studio.handle}/commissions/#{@work.commission.public_id}"}
              >{@work.commission.title}</LiveRedirect>
            {/if}
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
              <FancySelect
                id="offering-selector"
                name={:offering_idx}
                label="Offering"
                show_label
                class="offering-selector"
                items={[%{label: "None", value: nil, description: nil}] ++
                  (@studio.offerings
                   |> Enum.map(
                     &%{label: &1.name, value: &1.type, description: HtmlSanitizeEx.strip_tags(&1.description)}
                   ))}
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
    </Layout>
    """
  end
end
