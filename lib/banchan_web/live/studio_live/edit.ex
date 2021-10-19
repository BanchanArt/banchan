defmodule BanchanWeb.StudioLive.Edit do
  @moduledoc """
  Banchan studio profile viewing and editing.
  """
  use BanchanWeb, :surface_view

  alias Surface.Components.Form
  alias Surface.Components.Form.{ErrorTag, Field, Label, Submit, TextArea, TextInput}
  alias Surface.Components.Form.Input.InputContext

  alias Banchan.Studios
  alias Banchan.Studios.Studio
  alias BanchanWeb.Components.Layout
  alias BanchanWeb.Endpoint

  @impl true
  def mount(%{"handle" => handle}, session, socket) do
    socket = assign_defaults(session, socket)
    studio = Studios.get_studio_by_handle!(handle)

    if Studios.is_user_in_studio(socket.assigns.current_user, studio) do
      {:ok, assign(socket, studio: studio, changeset: Studio.changeset(studio, %{}))}
    else
      socket = put_flash(socket, :error, "Access denied")
      {:ok, push_redirect(socket, to: Routes.studio_show_path(Endpoint, :show, studio.handle))}
    end
  end

  @impl true
  def render(assigns) do
    ~F"""
    <Layout current_user={@current_user} flashes={@flash}>
      <h1 class="text-2xl">Edit Studio</h1>
      <h2 class="text-xl">{@studio.name}</h2>
      <div class="grid grid-cols-3 gap-4">
        <Form class="col-span-one" for={@changeset} change="change" submit="submit">
          <Field class="field" name={:name}>
            <Label class="label" />
            <div class="control has-icons-left">
              <InputContext :let={form: form, field: field}>
                <TextInput
                  class={"input", "is-danger": !Enum.empty?(Keyword.get_values(form.errors, field))}
                  opts={required: true}
                />
              </InputContext>
              <span class="icon is-small is-left">
                <i class="fas fa-user" />
              </span>
            </div>
            <ErrorTag class="help is-danger" />
          </Field>
          <Field class="field" name={:handle}>
            <Label class="label" />
            <div class="control has-icons-left">
              <InputContext :let={form: form, field: field}>
                <TextInput
                  class={"input", "is-danger": !Enum.empty?(Keyword.get_values(form.errors, field))}
                  opts={required: true}
                />
              </InputContext>
              <span class="icon is-small is-left">
                <i class="fas fa-at" />
              </span>
            </div>
            <ErrorTag class="help is-danger" />
          </Field>
          <Field class="field" name={:description}>
            <Label class="label" />
            <div class="control">
              <InputContext :let={form: form, field: field}>
                <TextArea
                  class={"textarea", "is-danger": !Enum.empty?(Keyword.get_values(form.errors, field))}
                  opts={required: true}
                />
              </InputContext>
            </div>
            <ErrorTag class="help is-danger" />
          </Field>
          <div class="field">
            <div class="control">
              <Submit
                class="text-center rounded-full py-1 px-5 bg-amber-200 text-black m-1"
                label="Save"
                opts={disabled: Enum.empty?(@changeset.changes) || !@changeset.valid?}
              />
            </div>
          </div>
        </Form>
      </div>
    </Layout>
    """
  end

  @impl true
  def handle_event("change", val, socket) do
    changeset =
      socket.assigns.studio
      |> Studio.changeset(val["studio"])
      |> Map.put(:action, :update)

    socket = assign(socket, changeset: changeset)
    {:noreply, socket}
  end

  @impl true
  def handle_event("submit", val, socket) do
    case Studios.update_studio_profile(socket.assigns.studio, val["studio"]) do
      {:ok, studio} ->
        socket = assign(socket, changeset: Studio.changeset(studio, %{}), studio: studio)
        socket = put_flash(socket, :info, "Profile updated")

        {:noreply,
         push_redirect(socket,
           to: Routes.studio_show_path(Endpoint, :show, studio.handle)
         )}

      other ->
        other
    end
  end
end
