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
  alias Banchan.Utils

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
          {to_string(idx), Map.update(opt, "price", "", &Utils.moneyfy/1)}
        end)
      )
    end)
  end

  def render(assigns) do
    ~F"""
    <Form
      class="max-w-lg mx-auto"
      for={@changeset}
      change="change"
      submit="submit"
      opts={autocomplete: "off"}
    >
      <TextInput
        name={:name}
        info="Name of the offering, as it should appear in the offering card."
        opts={required: true}
      />
      <TextInput
        name={:type}
        info="Lowercase, no-spaces, limited characters. This is what will show up in the url and must be unique."
        opts={required: true}
      />
      <TextArea
        name={:description}
        info="Description of the offering, as it should appear in the offering card."
        opts={required: true}
      />
      <TextArea
        name={:terms}
        info="Terms of service specific to this offering. Leave blank to use your studio's default terms."
      />
      <TextArea
        name={:template}
        info="Template that clients will see when they start filling out the commission request. Leave blank to use your studio's default template."
      />
      <TextInput
        name={:slots}
        info="Max slots available. Slots are used up as you accept commissions. Leave blank for unlimited slots."
      />
      <TextInput
        name={:max_proposals}
        info="Max proposals. Unlike slots, these are used as soon as someone makes a proposal. Use this setting to prevent your inbox from getting flooded with too many proposals. Leave blank for unlimited proposals."
      />
      <Checkbox
        name={:open}
        label="Open"
        info="Open up this offering for new proposals. The offering will remain visible if closed."
      />
      <Checkbox
        name={:hidden}
        label="Hide from Shop"
        info="Hide this offering from the shop. You will still be able to link people to it."
      />
      <h3>Options</h3>
      <InputContext :let={form: form}>
        <Inputs form={form} for={:options} :let={index: index}>
          <div>
            <h4>Option
              <Button primary={false} value={index} click="remove_option">Remove</Button>
            </h4>
            <TextInput name={:name} info="Name of the option." opts={required: true} />
            <TextArea name={:description} info="Description for the option." opts={required: true} />
            <TextInput name={:price} info="Quoted price for adding this option." opts={required: true} />
            <Checkbox
              name={:multiple}
              info="Allow multiple instances of this option at the same time."
              label="Allow Multiple"
            />
            <Checkbox name={:sticky} info="Once this option is added, it can't be removed." label="Sticky" />
            <Checkbox
              name={:default}
              info="Whether this option is added by default. Default options are also used to calculate your offering's base price."
              label="Default"
            />
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
    """
  end
end
