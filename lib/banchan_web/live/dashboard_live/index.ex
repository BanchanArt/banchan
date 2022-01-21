defmodule BanchanWeb.DashboardLive do
  @moduledoc """
  Artist dashboard
  """
  use BanchanWeb, :surface_view

  alias BanchanWeb.Components.Layout

  @impl true
  def mount(_params, session, socket) do
    socket = assign_defaults(session, socket)
    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~F"""
    <Layout current_user={@current_user} flashes={@flash}>
      <h1 class="text-2xl">Dashboard</h1>
      <h2 class="text-xl">Commissions</h2>
      <div class="overflow-x-auto">
        <table class="table w-full table-compact">
          <thead>
            <tr>
              <th>
                <label>
                  Select
                </label>
              </th>
              <th>User</th>
              <th>Commission</th>
              <th>Status</th>
              <th />
            </tr>
          </thead>
          <tbody>
            <tr>
              <th>
                <label>
                  <input type="checkbox" class="checkbox">
                </label>
              </th>
              <td>
                <div class="flex items-center space-x-3">
                  <img
                    src="/images/kat-chibi.jpeg"
                    alt="Avatar"
                    class="w-12 h-12 avatar mb-8 rounded-box ring ring-secondary ring-offset-base-100 ring-offset-2"
                  />
                  <div class="font-bold">
                    zkat
                  </div>
                </div>
              </td>
              <td>
                Thing 1 Example Commission
              </td>
              <td>Started</td>
              <th>
                <button class="btn btn-secondary btn-xs"><a href="/studios/kitteh-studio/commissions/thing-1/" class="link">details</a></button>
              </th>
            </tr>
            <tr>
              <th>
                <label>
                  <input type="checkbox" class="checkbox">
                </label>
              </th>
              <td>
                <div class="flex items-center space-x-3">
                  <img
                    src="/images/kat-chibi.jpeg"
                    alt="Avatar"
                    class="w-12 h-12 avatar mb-8 rounded-box ring ring-secondary ring-offset-base-100 ring-offset-2"
                  />
                  <div class="font-bold">
                    zkat
                  </div>
                </div>
              </td>
              <td>
                Thing 2 Example Commission
              </td>
              <td>Pending</td>
              <th>
                <button class="btn btn-secondary btn-xs"><a href="/studios/kitteh-studio/commissions/thing-2/" class="link">details</a></button>
              </th>
            </tr>
          </tbody>
          <tfoot>
            <tr>
              <th />
              <th>User</th>
              <th>Commission</th>
              <th>Status</th>
              <th />
            </tr>
          </tfoot>
        </table>
      </div>
    </Layout>
    """
  end
end
