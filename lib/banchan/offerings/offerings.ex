defmodule Banchan.Offerings do
  @moduledoc """
  Main context module for Offerings.
  """
  import Ecto.Query, warn: false

  alias Banchan.Accounts.User
  alias Banchan.Commissions.Commission
  alias Banchan.Offerings.{Notifications, Offering}
  alias Banchan.Repo
  alias Banchan.Uploads

  def new_offering(_, false, _) do
    {:error, :unauthorized}
  end

  def new_offering(studio, _current_user_member?, attrs, image \\ nil) do
    %Offering{studio_id: studio.id, card_img: image}
    |> Offering.changeset(attrs)
    |> Repo.insert()
  end

  def get_offering_by_type!(type, current_user_member?) do
    Repo.one!(
      from o in Offering,
        where: o.type == ^type and (^current_user_member? or not o.hidden)
    )
    |> Repo.preload(:options)
  end

  def change_offering(%Offering{} = offering, attrs \\ %{}) do
    Offering.changeset(offering, attrs)
  end

  def update_offering(_, false, _) do
    {:error, :unauthorized}
  end

  def update_offering(%Offering{} = offering, _current_user_member?, attrs, image \\ nil) do
    {:ok, ret} =
      Repo.transaction(fn ->
        open_before? = Repo.one(from o in Offering, where: o.id == ^offering.id, select: o.open)

        ret =
          offering
          |> Repo.preload(:card_img)
          |> change_offering(attrs)
          |> Ecto.Changeset.put_assoc(:card_img, image)
          |> Repo.update(returning: true)

        case ret do
          {:ok, changed} ->
            if !open_before? && changed.open do
              Notifications.offering_opened(changed)
            end

            {:ok, changed}

          {:error, error} ->
            {:error, error}
        end
      end)

    ret
  end

  def offering_base_price(%Offering{} = offering) do
    if Enum.empty?(offering.options) do
      nil
    else
      offering.options
      |> Enum.filter(& &1.default)
      |> Enum.map(&(&1.price || Money.new(0, :USD)))
      |> Enum.reduce(Money.new(0, :USD), &Money.add(&1, &2))
    end
  end

  def offering_available_slots(%Offering{} = offering) do
    {slots, count} =
      Repo.one(
        from(o in Offering,
          left_join: c in Commission,
          on:
            c.offering_id == o.id and
              c.status not in [:withdrawn, :approved, :submitted, :rejected],
          where: o.id == ^offering.id,
          group_by: [o.id, o.slots],
          select: {o.slots, count(c)}
        )
      )

    cond do
      is_nil(slots) ->
        nil

      count > slots ->
        0

      true ->
        slots - count
    end
  end

  def offering_available_proposals(%Offering{} = offering) do
    {max, count} =
      Repo.one(
        from(o in Offering,
          left_join: c in Commission,
          on: c.offering_id == o.id and c.status == :submitted,
          where: o.id == ^offering.id,
          group_by: [o.id, o.max_proposals],
          select: {o.max_proposals, count(c)}
        )
      )

    cond do
      is_nil(max) ->
        nil

      count > max ->
        0

      true ->
        max - count
    end
  end

  def make_card_image!(%User{} = uploader, src) do
    mog =
      Mogrify.open(src)
      |> Mogrify.format("jpeg")
      |> Mogrify.gravity("Center")
      |> Mogrify.resize_to_fill("640x360")
      |> Mogrify.save(in_place: true)

    image = Uploads.save_file!(uploader, mog.path, "image/jpeg", "card_image.jpg")
    File.rm!(mog.path)
    image
  end
end
