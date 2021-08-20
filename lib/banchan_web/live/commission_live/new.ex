defmodule BanchanWeb.CommissionLive.New do
  @moduledoc """
  Live page for Commission Proposals
  """
  use BanchanWeb, :surface_view

  alias Surface.Components.Form
  alias Surface.Components.Form.{Checkbox, ErrorTag, Field, Label, Submit, TextArea}
  alias Surface.Components.Form.Input.InputContext

  alias Banchan.Commissions.Commission
  alias Banchan.Studios

  alias BanchanWeb.Components.Commissions.Attachments
  alias BanchanWeb.Components.{Card, Layout}

  @impl true
  def mount(%{"slug" => slug}, session, socket) do
    socket = assign_defaults(session, socket)
    changeset = Commission.changeset(%Commission{status: :pending}, %{})
    studio = Studios.get_studio_by_slug!(slug)
    {:ok, assign(socket, studio: studio, changeset: changeset)}
  end

  # @impl true
  # def handle_event("submit", params, socket) do
  #   IO.inspect(params)
  #   {:noreply, socket}
  # end

  @impl true
  def render(assigns) do
    ~F"""
    <Layout current_user={@current_user} flashes={@flash}>
      <:hero>
        <section class="hero is-primary">
          <div class="hero-body">
            <p class="title">
              {@studio.name}
            </p>
            <p class="subtitle">
              {@studio.description}
            </p>
          </div>
          <div class="hero-foot">
            <nav class="tabs is-boxed">
              <div class="container">
                <ul>
                  <li class="is-active">
                    <a>Shop</a>
                  </li>
                  <li>
                    <a>About</a>
                  </li>
                  <li>
                    <a>Portfolio</a>
                  </li>
                  <li>
                    <a>Q&A</a>
                  </li>
                </ul>
              </div>
            </nav>
          </div>
        </section>
      </:hero>
      <div class="new-commission columns">
        <div class="column is-three-fifths">
          <h1 class="title">Illustration Commission</h1>
          <h2 class="subtitle">waist-up of your character(s) with background environment of your choice!</h2>
          <div class="content">
            <strong>These are all private commissions, meaning: non-commercial</strong>
            <p>You're only paying for my service to create the work not copyrights or licensing of the work itself!</p>
          </div>
          <Form for={@changeset} submit="submit">
            <div class="block">
              <Field class="field" name={:description}>
                <Label class="label" />
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
            </div>
            <div class="content block">
              <p>Please review the Terms of Service for this commission before submitting your request.</p>
              <p><strong>These Terms might vary between commission type</strong>.</p>
              <button type="button" class="button is-link">
                <span>View Terms of Service</span>
                <span class="icon is-small">
                  <i class="fas fa-external-link-alt" />
                </span>
              </button>
            </div>
            <Field class="field" name={:tos_ok}>
              <Label class="checkbox is-large">
                <Checkbox class="is-large" name={:tos_ok} opts={required: true} />
                I have read and agree to {@studio.name}'s <a href="#">Terms of Service</a>.
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

        <div class="column">
          <div id="sidebar">
            <div class="block sidebar-box">
              <Card>
                <:header>
                  Choose Products
                </:header>
                <div class="content">
                  <div class="tags has-addons">
                    <span class="tag is-medium is-success">
                      $150.00
                    </span>
                    <span class="tag is-medium">
                      Base Price
                    </span>
                  </div>
                  <ul>
                    <li>One Character</li>
                    <li>Full Color</li>
                    <li>Color Background</li>
                  </ul>
                  <hr>
                  <h5>Choose Add-ons</h5>
                  <ul>
                    <li>
                      <div class="tags has-addons">
                        <span class="tag is-medium is-success">
                          +$50.00
                        </span>
                        <span class="tag is-medium">
                          Extra Character
                        </span>
                      </div>
                    </li>
                    <li>
                      <div class="tags has-addons">
                        <span class="tag is-medium is-success">
                          +$50.00
                        </span>
                        <span class="tag is-medium">
                          Extra Character
                        </span>
                      </div>
                    </li>
                    <li>
                      <div class="tags has-addons">
                        <span class="tag is-medium is-success">
                          +$50.00
                        </span>
                        <span class="tag is-medium">
                          Mecha
                        </span>
                      </div>
                    </li>
                    <li>
                      <div class="tags has-addons">
                        <span class="tag is-medium is-success">
                          +$TBD
                        </span>
                        <span class="tag is-medium">
                          Custom Request
                        </span>
                      </div>
                    </li>
                  </ul>
                </div>
              </Card>
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
