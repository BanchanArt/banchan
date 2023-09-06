defmodule Banchan.Ecto.RichText do
  @moduledoc """
  Custom Ecto type for rich text that makes sure we're always dealing with
  basic html, even though data might originally be markdown.
  """
  use Ecto.Type
  def type, do: :string

  def cast(text) do
    ensure_basic_html(text)
  end

  def load(text) do
    ensure_basic_html(text)
  end

  def dump(text) do
    ensure_basic_html(text)
  end

  defp ensure_basic_html(text) when is_binary(text) do
    newtext =
      HtmlSanitizeEx.basic_html(text)
      |> String.replace(~r/<br\/?>/, "<br/>")

    if newtext |> String.replace("<br/>", "") |> String.match?(~r/<[a-zA-Z0-9]>/) do
      # We got some stuff that's already sanitized basic html!
      {:ok, newtext}
    else
      case Earmark.as_html(text) do
        {:ok, from_md, []} ->
          {:ok, from_md |> HtmlSanitizeEx.basic_html() |> String.replace(~r/<br\/?>/, "<br/>")}

        _ ->
          {:ok, newtext}
      end
    end
  end

  defp ensure_basic_html(_), do: :error
end
