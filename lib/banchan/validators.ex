defmodule Banchan.Validators do
  @moduledoc """
  Shared validators.
  """
  import Ecto.Changeset

  def validate_money(changeset, field) do
    validate_change(changeset, field, fn
      _, %Money{amount: amount} when amount >= 0 -> []
      _, "" -> []
      _, nil -> []
      _, _ -> [{field, "Must be a positive money amount."}]
    end)
  end

  def validate_markdown(changeset, field) do
    validate_change(changeset, field, fn _, data ->
      if data == HtmlSanitizeEx.markdown_html(data) do
        []
      else
        [{field, "Disallowed HTML detected. Some tags, like <script>, are not allowed."}]
      end
    end)
  end

  # :tags is hardcoded because the trigger expects the column to be called :tags
  def validate_tags(changeset) do
    changeset
    |> validate_change(:tags, fn field, tags ->
      if tags |> Enum.map(&String.downcase/1) ==
           tags |> Enum.map(&String.downcase/1) |> Enum.uniq() do
        []
      else
        [{field, "cannot have duplicate tags."}]
      end
    end)
    |> validate_change(:tags, fn field, tags ->
      if Enum.count(tags) > 10 do
        [{field, "cannot have more than 10 tags."}]
      else
        []
      end
    end)
    |> validate_change(:tags, fn field, tags ->
      if Enum.all?(tags, fn tag ->
           String.match?(tag, ~r/^.{0,100}$/)
         end) do
        []
      else
        [{field, "Tags can only be up to 100 characters long."}]
      end
    end)
  end
end
