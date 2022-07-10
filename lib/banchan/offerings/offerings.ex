defmodule Banchan.Offerings do
  @moduledoc """
  Main context module for Offerings.
  """
  import Ecto.Query, warn: false

  alias Banchan.Accounts.User
  alias Banchan.Commissions.Commission

  alias Banchan.Offerings.{
    GalleryImage,
    Notifications,
    Offering,
    OfferingOption,
    OfferingSubscription
  }

  alias Banchan.Repo
  alias Banchan.Studios.Studio
  alias Banchan.Uploads
  alias Banchan.Uploads.Upload

  def new_offering(_, false, _, _, _) do
    {:error, :unauthorized}
  end

  def new_offering(studio, true, attrs, card_image, gallery_images) do
    {:ok, ret} =
      Repo.transaction(fn ->
        max_idx =
          from(o in Offering, where: o.studio_id == ^studio.id, select: max(o.index))
          |> Repo.one!() ||
            0

        gallery_images =
          (gallery_images || [])
          |> Enum.with_index()
          |> Enum.map(fn {%Upload{} = upload, index} ->
            %GalleryImage{
              index: index,
              upload_id: upload.id
            }
          end)

        %Offering{
          studio_id: studio.id,
          card_img: card_image,
          gallery_imgs: gallery_images,
          index: max_idx + 1
        }
        |> Offering.changeset(attrs)
        |> Repo.insert()
      end)

    ret
  end

  def archive_offering(%Offering{}, false) do
    {:error, :unauthorized}
  end

  def archive_offering(%Offering{} = offering, true) do
    {:ok, new} =
      Repo.transaction(fn ->
        {1, [new]} =
          from(o in Offering,
            where: o.id == ^offering.id,
            select: o
          )
          |> Repo.update_all(set: [index: nil, archived_at: NaiveDateTime.utc_now()])

        current_index = new.index

        if !is_nil(current_index) do
          {_, _} =
            from(
              o in Offering,
              where: o.index >= ^current_index and not is_nil(o.index),
              update: [set: [index: o.index - 1]]
            )
            |> Repo.update_all([])
        end

        new
      end)

    {:ok, new}
  end

  def unarchive_offering(%Offering{}, false) do
    {:error, :unauthorized}
  end

  def unarchive_offering(%Offering{} = offering, true) do
    {:ok, ret} =
      Repo.transaction(fn ->
        max_idx =
          from(o in Offering, where: o.studio_id == ^offering.studio_id, select: max(o.index))
          |> Repo.one!() ||
            0

        {1, [new]} =
          from(o in Offering,
            where: o.id == ^offering.id,
            select: o
          )
          |> Repo.update_all(set: [index: max_idx + 1, archived_at: nil])

        {:ok, new}
      end)

    ret
  end

  def move_offering(%Offering{}, _, false) do
    {:error, :unauthorized}
  end

  def move_offering(%Offering{} = offering, new_index, true) when new_index >= 0 do
    {:ok, ret} =
      Repo.transaction(fn ->
        # "Remove" the existing offering
        {_, _} =
          from(o in Offering,
            where:
              o.studio_id ==
                ^offering.studio_id and not is_nil(o.index) and o.index > ^offering.index,
            update: [set: [index: o.index - 1]]
          )
          |> Repo.update_all([])

        # Shift everything after new index to the right.
        {_, _} =
          from(o in Offering,
            where:
              o.studio_id == ^offering.studio_id and not is_nil(o.index) and o.index >= ^new_index,
            update: [set: [index: o.index + 1]]
          )
          |> Repo.update_all([])

        {1, [o]} =
          from(o in Offering,
            where: o.id == ^offering.id,
            update: [set: [index: ^new_index]],
            select: o
          )
          |> Repo.update_all([])

        {:ok, o}
      end)

    ret
  end

  def get_offering_by_type!(%Studio{} = studio, type, current_user_member?) do
    Repo.one!(
      from o in Offering,
        where:
          o.studio_id == ^studio.id and o.type == ^type and
            (^current_user_member? or not o.hidden)
    )
    |> Repo.preload(:options)
  end

  def change_offering(%Offering{} = offering, attrs \\ %{}) do
    Offering.changeset(offering, attrs)
  end

  def update_offering(_, false, _, _, _) do
    {:error, :unauthorized}
  end

  def update_offering(%Offering{} = offering, true, attrs, card_image, gallery_images) do
    {:ok, ret} =
      Repo.transaction(fn ->
        open_before? = Repo.one(from o in Offering, where: o.id == ^offering.id, select: o.open)

        changeset =
          offering
          |> Repo.preload(:card_img)
          |> Repo.preload(:gallery_imgs)
          |> change_offering(attrs)

        changeset =
          if is_nil(card_image) do
            changeset
          else
            changeset |> Ecto.Changeset.put_assoc(:card_img, card_image)
          end

        changeset =
          if is_nil(gallery_images) do
            changeset
          else
            gallery_images =
              (gallery_images || [])
              |> Enum.with_index()
              |> Enum.map(fn {%Upload{} = upload, index} ->
                %GalleryImage{
                  index: index,
                  upload_id: upload.id
                }
              end)

            changeset |> Ecto.Changeset.put_assoc(:gallery_imgs, gallery_images)
          end

        ret = changeset |> Repo.update(returning: true)

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

  @doc """
  List offerings offered by a studio. Will take into account visibility
  based on whether the current user is a member of the studio and whether the
  offering is published.

  ## Examples

      iex> list_offerings(current_user, current_studio_member?)
      [%Offering{}, %Offering{}, %Offering{}]
  """
  def list_offerings(
        %User{} = current_user,
        current_user_member?,
        opts \\ []
      ) do
    q =
      from o in Offering,
        as: :offering,
        where: ^current_user_member? or o.hidden == false,
        left_join: sub in OfferingSubscription,
        on:
          sub.user_id == ^current_user.id and sub.offering_id == o.id and
            sub.silenced != true,
        left_lateral_join:
          used_slots in subquery(
            from c in Commission,
              where:
                c.offering_id == parent_as(:offering).id and
                  c.status not in [:withdrawn, :approved, :submitted, :rejected],
              group_by: [c.offering_id],
              select: %{used_slots: count(c.id)}
          ),
        left_lateral_join:
          default_prices in subquery(
            from oo in OfferingOption,
              where: oo.offering_id == parent_as(:offering).id,
              group_by: [oo.offering_id],
              select: %{
                prices:
                  type(fragment("array_agg(?)", oo.price), {:array, Money.Ecto.Composite.Type})
              }
          ),
        left_lateral_join:
          gallery_uploads in subquery(
            from i in GalleryImage,
              where: i.offering_id == parent_as(:offering).id,
              join: u in assoc(i, :upload),
              group_by: [i.offering_id],
              select: %{uploads: fragment("array_agg(row_to_json(?))", u)}
          ),
        order_by: [fragment("CASE WHEN ? IS NULL THEN 1 ELSE 0 END", o.index), o.index],
        select:
          merge(o, %{
            user_subscribed?: not is_nil(sub.id),
            used_slots: coalesce(used_slots.used_slots, 0),
            gallery_uploads:
              type(
                coalesce(
                  gallery_uploads.uploads,
                  fragment("ARRAY[]::json[]")
                ),
                {:array, Upload}
              ),
            option_prices:
              type(
                coalesce(default_prices.prices, fragment("ARRAY[]::money_with_currency[]")),
                {:array, Money.Ecto.Composite.Type}
              )
          })

    q =
      case Keyword.fetch(opts, :include_archived?) do
        {:ok, true} ->
          q |> where([o], is_nil(o.archived_at))

        _ ->
          q
      end

    q =
      case Keyword.fetch(opts, :studio) do
        {:ok, %Studio{} = studio} ->
          q |> where([o], o.studio_id == ^studio.id)

        :error ->
          q
      end

    Repo.all(q)
  end

  def offering_base_price(%Offering{} = offering) do
    if Enum.empty?(offering.option_prices) do
      nil
    else
      offering.option_prices
      |> Enum.reduce(%{}, fn price, acc ->
        current =
          Map.get(
            acc,
            price.currency,
            Money.new(0, price.currency)
          )

        Map.put(acc, price.currency, Money.add(current, price))
      end)
    end
  end

  def offering_available_slots(%Offering{} = offering, reload \\ false) do
    {slots, used_slots} =
      if reload do
        Repo.one(
          from o in Offering,
            left_join: c in assoc(o, :commissions),
            on: c.status not in [:withdrawn, :approved, :submitted, :rejected],
            where: o.id == ^offering.id,
            group_by: [o.id, o.slots],
            select: {o.slots, count(c)}
        )
      else
        {offering.slots, offering.used_slots}
      end

    cond do
      is_nil(slots) ->
        nil

      used_slots > slots ->
        0

      true ->
        slots - used_slots
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

  def make_card_image!(%User{} = uploader, src, true) do
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

  def offering_gallery_uploads(%Offering{} = offering) do
    from(i in GalleryImage,
      join: u in assoc(i, :upload),
      where: i.offering_id == ^offering.id,
      order_by: [asc: i.index],
      select: u
    )
    |> Repo.all()
  end

  def make_gallery_image!(%User{} = uploader, src, true) do
    mog =
      Mogrify.open(src)
      |> Mogrify.format("jpeg")
      |> Mogrify.save(in_place: true)

    image = Uploads.save_file!(uploader, mog.path, "image/jpeg", "gallery_image.jpg")
    File.rm!(mog.path)
    image
  end
end
