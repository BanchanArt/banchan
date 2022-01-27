defmodule BanchanWeb.StudioLive.New do
  @moduledoc """
  New studio creation page.
  """
  use BanchanWeb, :surface_view

  import Slug
  alias Surface.Components.Form
  alias Surface.Components.Form.{ErrorTag, Field, Label, Submit, TextArea, TextInput}
  alias Surface.Components.Form.Input.InputContext

  alias Banchan.Studios
  alias Banchan.Studios.Studio
  alias BanchanWeb.Components.Layout
  alias BanchanWeb.Endpoint

  @impl true
  def mount(_params, session, socket) do
    socket = assign_defaults(session, socket)
    changeset = Studio.changeset(%Studio{}, %{})
    {:ok, assign(socket, changeset: changeset)}
  end

  @impl true
  def render(assigns) do
    ~F"""
    <Layout current_user={@current_user} flashes={@flash}>
      <h1 class="text-2xl">New Studio</h1>

      <div class="grid grid-cols-3 gap-4">
        <Form
          class="col-span-1"
          for={@changeset}
          change="change"
          submit="submit"
          opts={autocomplete: "off"}
        >
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
                class="btn btn-secondary text-center rounded-full py-1 px-5 m-1"
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
  def handle_event("change", %{"studio" => studio, "_target" => target}, socket) do
    studio =
      if target == ["studio", "name"] do
        %{studio | "handle" => slugify(studio["name"])}
      else
        studio
      end

    changeset =
      %Studio{}
      |> Studio.changeset(studio)
      |> Map.put(:action, :update)

    socket = assign(socket, changeset: changeset)
    {:noreply, socket}
  end

  @impl true
  def handle_event("submit", val, socket) do
    case Studios.new_studio(%Studio{artists: [socket.assigns.current_user]}, val["studio"]) do
      {:ok, studio} ->
        put_flash(socket, :info, "Profile updated")
        {:noreply, redirect(socket, to: Routes.studio_shop_path(Endpoint, :show, studio.handle))}

      other ->
        other
    end
  end
end
