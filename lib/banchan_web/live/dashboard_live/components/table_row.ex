defmodule BanchanWeb.DashboardLive.Components.TableRow do
  @moduledoc """
  Rows for the commission table
  """
  use BanchanWeb, :component

  alias BanchanWeb.Endpoint

  alias Surface.Components.LiveRedirect

  prop data, :struct, required: true

  def render(assigns) do
    ~F"""
    <tr>
      <td>
        <div class="flex items-center space-x-3">
          <img class="w-6 inline-block" src={Routes.static_path(Endpoint, "/images/kat-chibi.jpeg")}>
          <div class="font-bold">
            {@data.client_handle}
          </div>
        </div>
      </td>
      <td>
        <div class="font-bold">
          {@data.studio_handle}
        </div>
      </td>
      <td>
        {@data.title}
      </td>
      <td>{@data.status}</td>
      <th>
        <LiveRedirect
          to={Routes.studio_commissions_show_path(
            Endpoint,
            :show,
            @data.studio_handle,
            @data.public_id
          )}
          label="details"
        />
      </th>
    </tr>
    """
  end
end
