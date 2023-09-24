defmodule BanchanWeb.StudioLive.Payouts do
  @moduledoc """
  Studio payouts page.
  """
  use BanchanWeb, :live_view

  import BanchanWeb.StudioLive.Helpers

  alias Banchan.Payments

  alias BanchanWeb.Components.{Button, Icon, InfiniteScroll, Layout, Stats}
  alias BanchanWeb.StudioLive.Components.{Payout, PayoutList}

  def mount(params, _session, socket) do
    {:ok, assign_studio_defaults(params, socket, true, true)}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    if socket.redirected do
      {:noreply, socket}
    else
      Payments.subscribe_to_payout_events(socket.assigns.studio)

      payout_id =
        case params do
          %{"payout_id" => payout_id} ->
            # NOTE: Phoenix LiveView's push_patch has an obnoxious bug with fragments, so
            # we have to manually remove them here.
            # See: https://github.com/phoenixframework/phoenix_live_view/issues/2041
            Regex.replace(~r/#.*$/, payout_id, "")

          _ ->
            nil
        end

      send(self(), :load_data)

      payout =
        if is_nil(payout_id) do
          nil
        else
          Map.get(socket.assigns, :payout, nil)
        end

      {:noreply,
       socket
       |> assign(payout_id: payout_id)
       |> assign(data_pending: true)
       |> assign(fypm_pending: false)
       |> assign(page: 1)
       |> assign(payout: payout)
       |> assign(results: Map.get(socket.assigns, :results, nil))
       |> assign(balance: Map.get(socket.assigns, :balance, nil))}
    end
  end

  def handle_event("load_more", _, socket) do
    if socket.assigns.results.total_entries >
         socket.assigns.page * socket.assigns.results.page_size do
      {:noreply, socket |> assign(page: socket.assigns.page + 1) |> fetch()}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("fypm", _, socket) do
    send(self(), :process_fypm)
    {:noreply, socket |> assign(fypm_pending: true)}
  end

  def handle_info(:load_data, socket) do
    payout =
      if socket.assigns.payout_id do
        Task.async(fn -> Payments.get_payout!(socket.assigns.payout_id) end)
      else
        Task.async(fn -> nil end)
      end

    results =
      Task.async(fn -> Payments.list_payouts(socket.assigns.studio, socket.assigns.page) end)

    balance = Task.async(fn -> Payments.get_banchan_balance(socket.assigns.studio) end)

    [payout, results, {:ok, balance}] = Task.await_many([payout, results, balance], 20_000)

    {:noreply,
     socket
     |> assign(data_pending: false)
     |> assign(payout: payout)
     |> assign(results: results)
     |> assign(balance: balance)}
  end

  def handle_info(:process_fypm, socket) do
    case Payments.payout_studio(socket.assigns.current_user, socket.assigns.studio) do
      {:ok, [payout, _ | _]} ->
        {:noreply,
         socket
         |> put_flash(
           :info,
           "Payouts sent! They should be in your account(s) starting #{payout.arrival_date |> Timex.to_datetime() |> Timex.format!("{ISOdate}")}."
         )}

      {:ok, [payout | _]} ->
        {:noreply,
         socket
         |> put_flash(
           :info,
           "Payout sent! It should be in your account on #{payout.arrival_date |> Timex.to_datetime() |> Timex.format!("{ISOdate}")}."
         )}

      {:error, %Stripe.Error{user_message: user_message}} ->
        {:noreply,
         socket
         |> assign(fypm_pending: false)
         |> put_flash(:error, "Payout failed: #{user_message}")}

      {:error, _err} ->
        {:noreply,
         socket
         |> assign(fypm_pending: false)
         |> put_flash(:error, "Payout failed due to an internal error.")}
    end
  end

  def handle_info(%{event: "payout_updated", payload: payout}, socket) do
    new_payout =
      if socket.assigns.payout && socket.assigns.payout.id == payout.id do
        payout
      else
        socket.assigns.payout
      end

    in_result = Enum.find(socket.assigns.results.entries, &(&1.id == payout.id))

    new_results =
      if in_result do
        new_entries =
          Enum.map(socket.assigns.results.entries, fn entry ->
            if entry.id == payout.id do
              payout
            else
              entry
            end
          end)

        Task.async(fn -> %{socket.assigns.results | entries: new_entries} end)
      else
        Task.async(fn -> Payments.list_payouts(socket.assigns.studio, socket.assigns.page) end)
      end

    new_balance = Task.async(fn -> Payments.get_banchan_balance(socket.assigns.studio) end)

    [new_results, {:ok, new_balance}] = Task.await_many([new_results, new_balance])

    {:noreply,
     socket
     |> assign(
       payout: new_payout,
       results: new_results,
       balance: new_balance,
       fypm_pending: false
     )}
  end

  defp payout_possible?(available) do
    !Enum.empty?(available) &&
      Enum.all?(available, &(&1.amount > 0))
  end

  defp fetch(%{assigns: %{results: results, page: page}} = socket) do
    socket
    |> assign(
      :results,
      %{
        results
        | entries:
            results.entries ++
              Payments.list_payouts(socket.assigns.studio, page).entries
      }
    )
  end

  defp print_money(money, studio) when is_list(money) do
    if Enum.empty?(money) do
      Payments.print_money(%Money{amount: 0, currency: studio.default_currency})
    else
      money
      |> Enum.map_join(", ", &Payments.print_money/1)
    end
  end

  defp print_money(%Money{} = money, _studio) do
    Payments.print_money(money)
  end

  @impl true
  def render(assigns) do
    ~F"""
    <Layout flashes={@flash} studio={@studio} context={:studio}>
      <div class="flex flex-col max-h-full p-4 grow">
        <div class={"bg-base-100 rounded-box max-w-4xl w-full mx-auto", "hidden sm:flex": !is_nil(@payout_id)}>
          {#if is_nil(@balance)}
            <div class="flex flex-col items-center w-full h-full py-20">
              <h2 class="sr-only">Loading...</h2>
              <Icon name="loader-2" size="6" class="animate-spin" />
            </div>
          {#else}
            <Stats class="divide-base-200">
              <Stats.Stat
                id="available"
                name="Available Balance"
                value={print_money(@balance.available, @studio)}
                subtext={"Pending: #{print_money(@balance.stripe_pending, @studio)}"}
              />
              <Stats.Stat
                name="Unreleased"
                subtext="(in current commissions)"
                value={print_money(@balance.held_back, @studio)}
              />
              <Stats.Stat name="Paid out to Date" value={print_money(@balance.paid, @studio)} />
            </Stats>
          {/if}
        </div>
        <div class={"divider", "hidden sm:flex": !is_nil(@payout_id)} />
        <div class="flex flex-row grow md:grow-0">
          <div class={"flex flex-col basis-full md:basis-1/4 sidebar", "hidden md:flex": @payout_id}>
            <div class="flex flex-col">
              <Button
                class="pl-4 mr-4"
                click="fypm"
                disabled={@fypm_pending || is_nil(@balance) || !payout_possible?(@balance.available)}
                opts={id: "fypm"}
              >
                {#if @fypm_pending}
                  <Icon name="loader-2" size="4" class="animate-spin" />
                {/if}
                Pay Out
              </Button>
              <div class="divider">History</div>
              {#if @results}
                <PayoutList studio={@studio} payout_id={@payout_id} payouts={@results.entries} />
              {/if}
              <InfiniteScroll id="payouts-infinite-scroll" page={@page} load_more="load_more" />
            </div>
          </div>
          {#if @payout_id}
            <div class="md:container basis-full md:basis-3/4 payout">
              <Payout
                id="payout"
                current_user={@current_user}
                studio={@studio}
                payout={@payout}
                data_pending={@data_pending}
              />
            </div>
          {/if}
        </div>
      </div>
    </Layout>
    """
  end
end
