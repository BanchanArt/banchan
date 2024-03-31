defmodule BanchanWeb.CommissionLive.Components.CommissionWork do
  @moduledoc """
  Component for creating and seeing the work connected to a commission.
  """
  use BanchanWeb, :live_component

  alias Banchan.Works
  alias Banchan.Works.Work
  alias Banchan.Works.WorkUpload

  alias Surface.Components.{Form, LiveRedirect}

  alias BanchanWeb.Components.Button

  alias BanchanWeb.Components.Form.{
    Checkbox,
    QuillInput,
    Submit,
    TagsInput,
    TextInput
  }

  prop attachments, :list, required: true
  prop invoice, :struct, required: true
  prop current_user, :struct, from_context: :current_user
  prop current_user_member?, :boolean, from_context: :current_user_member?
  prop commission, :struct, from_context: :commission
  prop studio, :struct, from_context: :studio

  data changeset, :struct

  @impl true
  def update(params, socket) do
    {:ok, socket |> assign(params) |> assign(changeset: nil)}
  end

  @impl true
  def handle_event("open_work_form", _, socket) do
    {:noreply, socket |> assign(changeset: %Work{} |> Work.changeset(%{}))}
  end

  def handle_event("close_work_form", _, socket) do
    {:noreply, socket |> assign(changeset: nil)}
  end

  def handle_event("change", %{"work" => work}, socket) do
    uploads =
      socket.assigns.attachments
      |> Enum.with_index()
      |> Enum.map(fn {atch, index} ->
        %WorkUpload{
          upload_id: atch.upload.id
        }
        |> WorkUpload.changeset(%{"index" => index})
      end)

    changeset =
      Work.changeset(%Work{}, Map.put(work, "uploads", uploads))
      |> Map.put(:action, :insert)

    {:noreply, assign(socket, changeset: changeset)}
  end

  def handle_event("submit", %{"work" => work}, socket) do
    uploads =
      socket.assigns.attachments
      |> Enum.map(fn atch ->
        atch.upload
      end)

    Works.new_work(
      socket.assigns.current_user,
      socket.assigns.studio,
      work,
      uploads: uploads,
      commission: socket.assigns.commission
    )
    |> case do
      {:ok, work} ->
        {:noreply,
         redirect(socket, to: ~p"/studios/#{socket.assigns.studio.handle}/works/#{work.public_id}")}

      {:error, bad_changeset} ->
        {:noreply, assign(socket, changeset: bad_changeset)}
    end
  end

  def render(assigns) do
    ~F"""
    <commission-work id={@id}>
      {#if !is_nil(@commission.work)}
        <LiveRedirect
          class="btn btn-primary"
          to={~p"/studios/#{@studio.handle}/works/#{@commission.work.public_id}"}
        >
          Go to Work
        </LiveRedirect>
      {#elseif @current_user_member? && @invoice.final && @invoice.status == :released}
        {#if is_nil(@changeset)}
          <Button click="open_work_form">Create As Work</Button>
        {#else}
          <Form for={@changeset} change="change" submit="submit">
            <TextInput class="title-input" show_label={false} name={:title} opts={placeholder: "Title"} />
            <QuillInput id="work-description" label="Description" name={:description} />
            <TagsInput id="work-tags" label="Tags" name={:tags} />
            <div class="flags-form">
              <Checkbox label="Mature" name={:mature} />
              <Checkbox label="Private" name={:private} />
            </div>
            <Checkbox
              label="Showcase"
              name={:showcase}
              caption="Showcased works will be shown first in your studio portfolio and offering galleries. Think of it as pinning!"
            />
            <div class="edit-buttons">
              <Submit label="Create Work" changeset={@changeset} />
              <Button label="Cancel" class="btn-error" click="close_work_form" />
            </div>
          </Form>
        {/if}
      {/if}
    </commission-work>
    """
  end
end
