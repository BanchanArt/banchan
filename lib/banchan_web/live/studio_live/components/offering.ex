defmodule BanchanWeb.StudioLive.Components.Offering do
  @moduledoc """
  Component for creating and editing Offerings.
  """
  use BanchanWeb, :live_component

  import Slug

  alias Surface.Components.Form
  alias Surface.Components.Form.Input.InputContext
  alias Surface.Components.Form.Inputs

  alias Banchan.Offerings
  alias Banchan.Offerings.{Offering, OfferingOption}

  alias BanchanWeb.Components.Button
  alias BanchanWeb.Components.Form.{Checkbox, Submit, TextArea, TextInput}

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
    options = Ecto.Changeset.fetch_field!(socket.assigns.changeset, :options) ++ [changeset]

    offering_changeset =
      socket.assigns.changeset
      |> Ecto.Changeset.put_assoc(:options, options)

    {:noreply, assign(socket, changeset: offering_changeset)}
  end

  @impl true
  def handle_event("remove_option", %{"value" => index}, socket) do
    {index, ""} = Integer.parse(index)
    options = Ecto.Changeset.fetch_field!(socket.assigns.changeset, :options)
    options = List.delete_at(options, index)

    offering_changeset =
      socket.assigns.changeset
      |> Ecto.Changeset.put_assoc(:options, options)

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
        <TextInput name={:name} opts={required: true} />
        <TextInput name={:type} opts={required: true} />
        <TextArea name={:description} opts={required: true} />
        <TextArea name={:terms} />
        <h3>Options</h3>
        <InputContext :let={form: form}>
          <Inputs form={form} for={:options} :let={index: index}>
            <div>
              <h4>Option
                <Button is_primary={false} value={index} click="remove_option">Remove</Button>
              </h4>
              <TextInput name={:name} opts={required: true} />
              <TextArea name={:description} opts={required: true} />
              <TextInput name={:price} opts={required: true} />
              <Checkbox name={:sticky} label="Sticky" />
              <Checkbox name={:default} label="Default" />
            </div>
          </Inputs>
        </InputContext>
        <div class="field">
          <div class="control">
            <Button click="add_option" label="Add Option" />
          </div>
        </div>
        <Submit changeset={@changeset} label="Save" />
      </Form>
    </div>
    """
  end
end
