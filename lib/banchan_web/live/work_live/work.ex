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
  alias Banchan.Works.Work

  alias BanchanWeb.Components.{
    Icon,
    Layout,
    RichText,
    Tag
  }

  alias BanchanWeb.WorkLive.Components.WorkUploads

  alias Surface.Components.{
    Form,
    LiveFileInput,
    LivePatch,
    LiveRedirect
  }

  alias BanchanWeb.Components.Form.{
    Checkbox,
    HiddenInput,
    QuillInput,
    Submit,
    TagsInput,
    TextInput
  }

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> allow_upload(:uploads,
       accept: :any,
       max_entries: 10,
       max_file_size: Uploads.max_upload_size(),
       progress: fn :uploads, entry, socket ->
         dbg(entry)
         {:noreply, socket}
       end
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

    changeset =
      if socket.assigns.live_action == :edit do
        Work.changeset(work, %{})
      end

    {:noreply,
     socket
     |> assign(
       changeset: changeset,
       work: work,
       can_download?: Works.can_download_uploads?(socket.assigns.current_user, work),
       work_uploads: work.uploads |> Enum.map(&{:existing, &1})
     )}
  end

  def handle_params(params, _url, socket) do
    socket = assign_studio_defaults(params, socket, true, true)

    work = %Work{} |> Repo.preload([:uploads, :studio])

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

    {:noreply,
     socket
     |> assign(
       work: work,
       can_download?: false,
       changeset: changeset,
       work_uploads: work.uploads,
       commission: commission || nil,
       offering: offering || nil
     )}
  end

  @impl true
  def handle_event("change", %{"work" => work}, socket) do
    changeset =
      Work.changeset(socket.assigns.work, work)
      |> Map.put(:action, if(is_nil(socket.assigns.work.id), do: :insert, else: :update))

    {:noreply, assign(socket, changeset: changeset)}
  end

  def handle_event("submit", %{"work" => work}, socket)
      when is_nil(socket.assigns.work.id) do
    uploads =
      consume_uploaded_entries(socket, :uploads, fn %{path: path}, entry ->
        {:ok,
         Uploads.save_file!(
           socket.assigns.current_user,
           path,
           entry.client_type,
           entry.client_name
         )}
      end)

    Works.new_work(
      socket.assigns.current_user,
      socket.assigns.studio,
      work,
      uploads,
      commission: socket.assigns.commission,
      offering: socket.assigns.offering
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
    changeset = Work.changeset(socket.assigns.work, work)

    Works.update_work(changeset)
    |> case do
      {:ok, work} ->
        {:noreply,
         redirect(socket, to: ~p"/studios/#{socket.assigns.studio.handle}/works/#{work.public_id}")}

      {:error, bad_changeset} ->
        {:noreply, assign(socket, changeset: bad_changeset)}
    end
  end

  def handle_info({:updated_uploads, _, uploads}, socket) do
    changeset =
      Work.changeset(
        socket.assigns.work,
        socket.assigns.changeset.params |> Map.put("upload_count", Enum.count(uploads))
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
      @apply flex-col gap-4;
      }

      .preview-column-desktop {
      @apply hidden md:flex col-span-2 order-2;
      }

      .preview-column-mobile {
      @apply flex md:hidden;
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
              <LiveRedirect to={~p"/studios/#{@work.studio.handle}/offerings/#{@work.offering.type}"}>{@work.offering.name}</LiveRedirect>
            {/if}
            <span>
              by
            </span>
            <LiveRedirect to={~p"/studios/#{@work.studio.handle}"}>{@work.studio.name}</LiveRedirect>
          </div>
          <div class="flags-show">
            <span :if={@work.mature} title="Mature">M</span>
            <span :if={@work.private} title="Private">Private</span>
          </div>
          <div class="preview-column preview-column-mobile">
            <WorkUploads
              id="work-uploads-mobile"
              send_updates_to={self()}
              studio={@studio}
              work={@work}
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
            {/if}
          </div>
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
                to={~p"/studios/#{@work.studio.handle}/commissions/#{@work.commission.public_id}"}
              >{@work.commission.title}</LiveRedirect>
            {/if}
            {#if @current_user_member?}
              <LivePatch
                class="btn btn-success"
                to={~p"/studios/#{@work.studio.handle}/works/#{@work.public_id}/edit"}
              >Edit Work</LivePatch>
            {/if}
          {#else}
            <div class="work-form">
              <HiddenInput name={:upload_count} value={Enum.count(@work_uploads)} />
              <QuillInput id="work-description" label="Description" name={:description} />
              <TagsInput id="work-tags" label="Tags" name={:tags} />
              <div class="flags-form">
                <Checkbox label="Mature" name={:mature} />
                <Checkbox label="Private" name={:private} />
              </div>
              {#if is_nil(@work.id)}
                <Submit label="Create Work" changeset={@changeset} />
              {#else}
                <div class="edit-buttons">
                  <Submit label="Save" changeset={@changeset} />
                  <LivePatch
                    class="btn btn-error"
                    to={~p"/studios/#{@work.studio.handle}/works/#{@work.public_id}"}
                  >Cancel</LivePatch>
                </div>
              {/if}
            </div>
          {/if}
        </div>
        <div class="preview-column preview-column-desktop">
          <WorkUploads
            id="work-uploads-desktop"
            send_updates_to={self()}
            studio={@studio}
            work={@work}
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
          {/if}
        </div>
      </Form>
    </Layout>
    """
  end
end
