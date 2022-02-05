defmodule BanchanWeb.DashboardLive.Components.TableLink do
  @moduledoc """
  Header links for dashboard table
  """
  use BanchanWeb, :component

  alias Surface.Components.LivePatch

  prop params, :map, required: true
  prop field, :string, required: true
  prop direction_q, :string, default: "dir"
  prop field_q, :string, default: "by"
  prop page_q, :string, default: "pg"

  slot default

  def render(assigns) do
    direction = assigns.params[assigns.direction_q]

    opts =
      [
        page: 0,
        direction_q: assigns.direction_q,
        field_q: assigns.field_q,
        page_q: assigns.page_q
      ] ++
        if assigns.params[assigns.field_q] == to_string(assigns.field) do
          [
            by: assigns.field,
            dir: reverse(direction)
          ]
        else
          [
            by: assigns.field,
            dir: "desc"
          ]
        end

    ~F"""
    <LivePatch to={"?" <> querystring(@params, opts)}>
      <#slot />
    </LivePatch>
    """
  end

  defp querystring(params, opts) do
    params = params |> Plug.Conn.Query.encode() |> URI.decode_query()

    opts = %{
      # for later
      opts[:page_q] => opts[:page],
      opts[:field_q] => opts[:by] || params[opts[:field_q]] || nil,
      opts[:direction_q] => opts[:dir] || params[opts[:direction_q]] || nil
    }

    params
    |> Map.merge(opts)
    |> Enum.filter(fn {_, v} -> v != nil end)
    |> Enum.into(%{})
    |> URI.encode_query()
  end

  defp reverse("desc"), do: "asc"
  defp reverse(_), do: "desc"
end
