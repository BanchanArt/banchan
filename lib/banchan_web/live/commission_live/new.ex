defmodule BanchanWeb.CommissionLive.New do
  @moduledoc """
  Live page for Commission Proposals
  """
  use BanchanWeb, :surface_view

  alias Surface.Components.Form
  alias Surface.Components.Form.{Checkbox, ErrorTag, Field, Label, Submit, TextArea, TextInput}
  alias Surface.Components.Form.Input.InputContext

  alias Banchan.Commissions.Commission
  alias Banchan.Studios

  alias BanchanWeb.Components.Commissions.{
    Attachments,
    Summary,
  }
  alias BanchanWeb.Components.Layout

  @impl true
  def mount(%{"slug" => slug}, session, socket) do
    socket = assign_defaults(session, socket)
    changeset = Commission.changeset(%Commission{status: :pending}, %{})
    studio = Studios.get_studio_by_slug!(slug)
    {:ok, assign(socket, studio: studio, changeset: changeset)}
  end

  @impl true
  def handle_event("submit", params, socket) do
    IO.inspect(params)
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~F"""
    <Layout current_user={@current_user} flashes={@flash}>
      <div class="new-commission columns">
        <div class="column is-three-quarters">
          <h1 class="title">New Commission</h1>
          <hr>

          <Form for={:message} submit="submit">
            <Field class="field" name={:title}>
              <Label class="label" />
              <div class="control">
                <InputContext :let={form: form, field: field}>
                  <TextInput
                    class={"input", "is-danger": !Enum.empty?(Keyword.get_values(form.errors, field))}
                    opts={required: true, placeholder: "Commission Title"}
                  />
                </InputContext>
              </div>
              <ErrorTag class="help is-danger" />
            </Field>
            <Field class="field" name={:message}>
              <Label class="label">Description</Label>
              <div class="control">
                <InputContext :let={form: form, field: field}>
                  <TextArea
                    class={"textarea", "is-danger": !Enum.empty?(Keyword.get_values(form.errors, field))}
                    opts={required: true, placeholder: "Here's what I'd like..."}
                  />
                </InputContext>
              </div>
              <ErrorTag class="help is-danger" />
            </Field>
            <Field class="field" name={:tos_ok}>
              <Label class="checkbox">
                <Checkbox name={:tos_ok} opts={required: true} />
                I have read {@studio.name}'s <a href="#">Terms of Service</a>.
              </Label>
            </Field>
            <div class="field">
              <div class="control">
                <Submit
                  class="button is-link"
                  label="Submit"
                  opts={disabled: Enum.empty?(@changeset.changes) || !@changeset.valid?}
                />
              </div>
            </div>
          </Form>
        </div>

        <div class="column is-one-quarter">
          <div id="sidebar">
            <div class="block sidebar-box">
              <Summary id="commission-summary" />
            </div>

            <div class="block sidebar-box">
              <Attachments id="commission-attachments" />
            </div>
          </div>
        </div>
      </div>
    </Layout>
    """
  end
end
