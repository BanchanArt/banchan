defmodule BanchanWeb.StudioLive.Pages.Commissions.New do
  @moduledoc """
  Subpage for creating a new commission based on an offering type.
  """
  use BanchanWeb, :live_component

  alias Surface.Components.Form
  alias Surface.Components.Form.{Checkbox, ErrorTag, Field, Label, Submit, TextArea}
  alias Surface.Components.Form.Input.InputContext

  alias Banchan.Commissions.Commission

  alias BanchanWeb.Components.Card
  alias BanchanWeb.Components.Commissions.Attachments

  prop studio, :struct, required: true
  prop offering, :struct, required: true

  data changeset, :struct, default: Commission.changeset(%Commission{status: :pending}, %{})

  def render(assigns) do
    ~F"""
    <div class="grid grid-cols-5 gap-4">
      <div class="col-span-3">
        <h1 class="text-2xl">Illustration Commission</h1>
        <h2 class="text-xl">waist-up of your character(s) with background environment of your choice!</h2>
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
            <button type="button" class="btn btn-secondary text-center rounded-full py-1 px-5 m-1">
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
                class="btn btn-secondary text-center rounded-full py-1 px-5 m-1"
                label="Submit"
                opts={disabled: Enum.empty?(@changeset.changes) || !@changeset.valid?}
              />
            </div>
          </div>
        </Form>
      </div>

      <div class="col-span-2">
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
    """
  end
end
