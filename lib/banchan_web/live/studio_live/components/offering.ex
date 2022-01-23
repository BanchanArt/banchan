defmodule BanchanWeb.StudioLive.Components.Offering do
  @moduledoc """
  Component for creating and editing Offerings.
  """
  use BanchanWeb, :live_component

  import Slug

  alias Surface.Components.Form
  alias Surface.Components.Form.{ErrorTag, Inputs, Field, Label, Submit, TextArea, TextInput}
  alias Surface.Components.Form.Input.InputContext

  alias Banchan.Offerings
  alias Banchan.Offerings.{Offering, OfferingOption}

  prop changeset, :struct, required: true

  # TODO: Switch to using this when the following bugs are both fixed and released:
  # * https://github.com/surface-ui/surface/issues/563
  # * https://github.com/phoenixframework/phoenix_live_view/issues/1850
  #
  # prop submit, :event, required: true
  prop submit, :string, required: true

  @impl true
  def handle_event("submit", %{"offering" => offering}, socket) do
    offering = moneyfy_offering(offering)
    send(self(), {socket.assigns.submit, offering})
    {:noreply, socket}
  end

  @impl true
  def handle_event("add_option", _, socket) do
    changeset = %OfferingOption{} |> OfferingOption.changeset(%{})
    options = Map.get(socket.assigns.changeset.changes, :options, []) ++ [changeset]

    offering_changeset =
      socket.assigns.changeset
      |> Map.put(:changes, %{options: options})

    {:noreply, assign(socket, changeset: offering_changeset)}
  end

  @impl true
  def handle_event("change", %{"offering" => offering, "_target" => target}, socket) do
    offering =
      if target == ["offering", "name"] do
        %{offering | "type" => slugify(offering["name"])}
      else
        offering
      end

    offering = moneyfy_offering(offering)

    changeset =
      %Offering{}
      |> Offerings.change_offering(offering)
      |> Map.put(:action, :update)

    socket = assign(socket, changeset: changeset)
    {:noreply, socket}
  end

  defp moneyfy_offering(offering) do
    offering = Map.update(offering, "base_price", "", &moneyfy/1)
    # *sigh*
    Map.update(offering, "options", [], fn options ->
      Map.new(
        Enum.map(Enum.with_index(Map.values(options)), fn {opt, idx} ->
          {to_string(idx), Map.update(opt, "price", "", &moneyfy/1)}
        end)
      )
    end)
  end

  defp moneyfy(base_price) do
    # TODO: In the future, we can replace this :USD with a param and the DB will be fine.
    case Money.parse(base_price, :USD) do
      {:ok, money} ->
        money

      :error ->
        base_price
    end
  end

  def render(assigns) do
    ~F"""
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
        <Field class="field" name={:type}>
          <Label class="label" />
          <div class="control has-icons-left">
            <InputContext :let={form: form, field: field}>
              <TextInput
                class={"input", "is-danger": !Enum.empty?(Keyword.get_values(form.errors, field))}
                opts={required: true}
              />
            </InputContext>
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
        <Field class="field" name={:terms}>
          <Label class="label" />
          <div class="control">
            <InputContext :let={form: form, field: field}>
              <TextArea
                class={"textarea", "is-danger": !Enum.empty?(Keyword.get_values(form.errors, field))}
              />
            </InputContext>
          </div>
          <ErrorTag class="help is-danger" />
        </Field>
        <Field class="field" name={:base_price}>
          <Label class="label" />
          <div class="control">
            <InputContext :let={form: form, field: field}>
              <TextInput
                class={"input", "is-danger": !Enum.empty?(Keyword.get_values(form.errors, field))}
              />
            </InputContext>
          </div>
          <ErrorTag class="help is-danger" />
        </Field>
        <h3>Options</h3>
        <InputContext :let={form: form}>
          <Inputs form={form} for={:options}>
            <h4>Option</h4>
            <Field class="field" name={:name}>
              <Label class="label" />
              <div class="control">
                <InputContext :let={form: form, field: field}>
                  <TextInput
                    class={"input", "is-danger": !Enum.empty?(Keyword.get_values(form.errors, field))}
                  />
                </InputContext>
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
            <Field class="field" name={:price}>
              <Label class="label" />
              <div class="control">
                <InputContext :let={form: form, field: field}>
                  <TextInput
                    class={"input", "is-danger": !Enum.empty?(Keyword.get_values(form.errors, field))}
                  />
                </InputContext>
              </div>
              <ErrorTag class="help is-danger" />
            </Field>
          </Inputs>
        </InputContext>
        <div class="field">
          <div class="control">
            <button
              class="btn btn-secondary text-center rounded-full py-1 px-5 m-1"
              type="button"
              :on-click="add_option"
            >Add Option</button>
          </div>
        </div>
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
    """
  end
end