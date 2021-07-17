defmodule BanchanWeb.CommissionLive.Show do
  @moduledoc """
  Main page for viewing and interacting with a Commission
  """
  use BanchanWeb, :surface_view

  alias Surface.Components.Form
  alias Surface.Components.Form.{ErrorTag, Field, Label, Submit, TextArea}
  alias Surface.Components.Form.Input.InputContext

  alias Banchan.Commissions.Commission
  alias BanchanWeb.Components.Layout
  alias BanchanWeb.Endpoint

  @impl true
  def mount(_params, session, socket) do
    socket = assign_defaults(session, socket)
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => _id}, _, socket) do
    {:noreply,
     socket
     |> assign(commission: %Commission{}, changeset: Commission.changeset(%Commission{}, %{}))}
  end

  @impl true
  def render(assigns) do
    ~F"""
    <Layout current_user={@current_user} flashes={@flash}>
      <h1 class="title">Two-character drawing of me and my gf's FFXIV OCs</h1>
      <h2 class="subtitle"><strong>@{@current_user.handle}</strong> requested this commission 3 days ago.</h2>
      <hr>
      <div class="commission columns">
        <div class="timeline column is-three-quarters">
          <article class="timeline-item message is-link light">
            <div class="message-header">
              <div class="level">
                <div class="level-left">
                  <figure class="image is-24x24">
                    <img class="is-rounded" src={Routes.static_path(Endpoint, "/images/kat-chibi.jpeg")}>
                  </figure>
                  @{@current_user.handle} commented 3 days ago.
                </div>
              </div>
            </div>
            <div class="message-body">
              <div class="content">
                Hello I would like a really nice commission of my cool OC. I've attached some screenshots.
              </div>
              <div class="level">
                <div class="level-left">
                  <figure class="image is-96x96">
                    <img src={Routes.static_path(Endpoint, "/images/penana-left.png")}>
                  </figure>
                  <figure class="image is-96x96">
                    <img src={Routes.static_path(Endpoint, "/images/penana-right.png")}>
                  </figure>
                  <figure class="image is-96x96">
                    <img src={Routes.static_path(Endpoint, "/images/penana-front.png")}>
                  </figure>
                </div>
              </div>
            </div>
          </article>
          <p class="timeline-item"><i class="fas fa-clipboard-check" /> @{@current_user.handle} submitted this commission 3 days ago.</p>
          <article class="timeline-item message is-link light">
            <div class="message-header">
              <div class="level">
                <div class="level-left">
                  <figure class="image is-24x24">
                    <img class="is-rounded" src={Routes.static_path(Endpoint, "/images/denizen_default_icon.png")}>
                  </figure>
                  @skullbunnygalaxy commented 2 days ago.
                </div>
              </div>
            </div>
            <div class="message-body">
              <div class="content">
                <p>Hi, I'm happy to work on this! It sounds really cute.</p>
                <p>I can get started as soon as I receive the initial payment!</p>
              </div>
            </div>
          </article>
          <p class="timeline-item"><i class="fas fa-clipboard-check" /> @skullbunnygalaxy accepted this commission 2 days ago.</p>
          <p class="timeline-item"><i class="fas fa-file-invoice-dollar" /> @skullbunnygalaxy requested <strong>$100.25</strong></p>
          <p class="timeline-item"><i class="fas fa-donate" /> @{@current_user.handle} paid <strong>$100.25</strong></p>
          <p class="timeline-item"><i class="fas fa-palette" /> @skullbunnygalaxy started working on this commission.</p>
          <article class="timeline-item message is-link light">
            <div class="message-header">
              <div class="level">
                <div class="level-left">
                  <figure class="image is-24x24">
                    <img class="is-rounded" src={Routes.static_path(Endpoint, "/images/denizen_default_icon.png")}>
                  </figure>
                  @skullbunnygalaxy commented 2 days ago.
                </div>
              </div>
            </div>
            <div class="message-body">
              <div class="content">
                Hey can you tell me more about this character? What's their favorite food?
              </div>
            </div>
          </article>
          <p class="timeline-item"><small><i class="fas fa-hourglass-half" /> @skullbunnygalaxy changed the status to Waiting for Customer.</small></p>
          <hr />
          <Form for={@changeset}>
            <Field class="field" name={:message}>
              <Label class="label">Send a Message</Label>
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
                  class="button is-link"
                  label="Send"
                  opts={disabled: Enum.empty?(@changeset.changes) || !@changeset.valid?}
                />
              </div>
            </div>
          </Form>
          <p><small>Please remember that all interactions are covered by the artist's <a href="#">Terms of Service</a>.</small></p>
        </div>
        <div class="column is-one-quarter sidebar">
          <div class="sidebar-box content">
            <p><strong>Offerings</strong></p>
            <ul class="offering-list">
              <li class="offering">
                2 characters
              </li>
              <li class="offering">
                full color
              </li>
              <li class="offering">
                color background
              </li>
            </ul>
          </div>
          <hr>
          <div class="sidebar-box content">
            <p><strong>Status</strong></p>
            <p><i class="fas fa-hourglass-half" /> Waiting for Customer</p>
          </div>
          <hr>
          <div class="sidebar-box content">
            <p><strong>Estimated</strong></p>
            <p><i class="fas fa-calculator" /> $250.00</p>
          </div>
          <hr>
          <div class="sidebar-box content">
            <p><strong>Paid</strong></p>
            <p><i class="fas fa-donate" /> $100.25</p>
          </div>
          <hr>
          <div class="sidebar-box content">
            <p><strong>Attachments</strong></p>
            <div class="level">
              <div class="level-left">
                <figure class="image is-96x96">
                  <img src={Routes.static_path(Endpoint, "/images/penana-left.png")}>
                </figure>
                <figure class="image is-96x96">
                  <img src={Routes.static_path(Endpoint, "/images/penana-right.png")}>
                </figure>
                <figure class="image is-96x96">
                  <img src={Routes.static_path(Endpoint, "/images/penana-front.png")}>
                </figure>
              </div>
            </div>
          </div>
        </div>
      </div>
    </Layout>
    """
  end
end
