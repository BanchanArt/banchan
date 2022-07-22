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
  alias Banchan.Workers.Thumbnailer

  def new_offering(_, false, _, _) do
    {:error, :unauthorized}
  end

  def new_offering(studio, true, attrs, gallery_images) do
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

  def get_offering_by_type!(%Studio{} = studio, type, current_user_member?, current_user \\ nil) do
    q =
      from o in Offering,
        as: :offering,
        left_lateral_join:
          gallery_uploads in subquery(
            from i in GalleryImage,
              where: i.offering_id == parent_as(:offering).id,
              join: u in assoc(i, :upload),
              group_by: [i.offering_id],
              select: %{uploads: fragment("array_agg(row_to_json(?))", u)}
          ),
        left_lateral_join:
          used_slots in subquery(
            from c in Commission,
              where:
                c.offering_id == parent_as(:offering).id and
                  c.status not in [:withdrawn, :approved, :submitted, :rejected],
              group_by: [c.offering_id],
              select: %{used_slots: count(c.id)}
          ),
        where:
          o.studio_id == ^studio.id and o.type == ^type and
            (^current_user_member? or not o.hidden),
        select:
          merge(o, %{
            used_slots: coalesce(used_slots.used_slots, 0),
            gallery_uploads:
              type(
                coalesce(
                  gallery_uploads.uploads,
                  fragment("ARRAY[]::json[]")
                ),
                {:array, Upload}
              )
          })

    q =
      if current_user do
        q
        |> join(:left, [offering: o], sub in OfferingSubscription,
          on:
            sub.user_id == ^current_user.id and sub.offering_id == o.id and
              sub.silenced != true,
          as: :subscribed
        )
        |> select_merge([o, subscribed: sub], %{
          user_subscribed?: not is_nil(sub.id)
        })
      else
        q
      end

    q
    |> Repo.one!()
    |> Repo.preload([:options, :studio, :card_img])
  end

  def change_offering(%Offering{} = offering, attrs \\ %{}) do
    Offering.changeset(offering, attrs)
  end

  def update_offering(_, false, _, _) do
    {:error, :unauthorized}
  end

  def update_offering(%Offering{} = offering, true, attrs, gallery_images) do
    {:ok, ret} =
      Repo.transaction(fn ->
        open_before? = Repo.one(from o in Offering, where: o.id == ^offering.id, select: o.open)

        changeset =
          offering
          |> Repo.preload(:gallery_imgs)
          |> change_offering(attrs)

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
  # credo:disable-for-next-line Credo.Check.Refactor.CyclomaticComplexity
  def list_offerings(opts \\ []) do
    q =
      from o in Offering,
        as: :offering,
        join: s in assoc(o, :studio),
        as: :studio,
        left_lateral_join:
          used_slots in subquery(
            from c in Commission,
              where:
                c.offering_id == parent_as(:offering).id and
                  c.status not in [:withdrawn, :approved, :submitted, :rejected],
              group_by: [c.offering_id],
              select: %{used_slots: count(c.id)}
          ),
        as: :used_slots,
        left_lateral_join:
          default_prices in subquery(
            from oo in OfferingOption,
              where: oo.offering_id == parent_as(:offering).id and oo.default,
              group_by: [oo.offering_id],
              select: %{
                prices:
                  type(fragment("array_agg(?)", oo.price), {:array, Money.Ecto.Composite.Type}),
                # NB(zkat): This is hacky to the point of uselessness if we end up
                # having a ton of different currencies listed, but it's serviceable for now.
                sum: fragment("sum((?).amount)", oo.price)
              }
          ),
        as: :default_prices,
        left_lateral_join:
          gallery_uploads in subquery(
            from i in GalleryImage,
              where: i.offering_id == parent_as(:offering).id,
              join: u in assoc(i, :upload),
              group_by: [i.offering_id],
              select: %{uploads: fragment("array_agg(row_to_json(?))", u)}
          ),
        as: :gallery_uploads,
        select:
          merge(o, %{
            studio: s,
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
      case Keyword.fetch(opts, :include_disabled) do
        {:ok, true} ->
          q

        _ ->
          q
          |> join(:left, [studio: s], disable_info in assoc(s, :disable_info), as: :disable_info)
          |> where([disable_info: disable_info], is_nil(disable_info))
      end

    q =
      case Keyword.fetch(opts, :query) do
        {:ok, nil} ->
          q

        {:ok, query} ->
          q
          |> where([o], fragment("websearch_to_tsquery(?) @@ (?).search_vector", ^query, o))

        :error ->
          q
      end

    q =
      case Keyword.fetch(opts, :include_archived?) do
        {:ok, true} ->
          q |> where([o], is_nil(o.archived_at))

        _ ->
          q
      end

    q =
      case Keyword.fetch(opts, :studio) do
        {:ok, nil} ->
          q

        {:ok, %Studio{} = studio} ->
          q |> where([o], o.studio_id == ^studio.id)

        :error ->
          q
      end

    q =
      case Keyword.fetch(opts, :current_user) do
        {:ok, %User{} = current_user} ->
          q
          |> where(
            [o],
            o.mature != true or (o.mature == true and ^current_user.mature_ok == true)
          )
          |> join(:left, [o], sub in OfferingSubscription,
            on:
              sub.user_id == ^current_user.id and sub.offering_id == o.id and
                sub.silenced != true,
            as: :subscription
          )
          |> join(:inner, [], user in User, on: user.id == ^current_user.id, as: :current_user)
          |> where(
            [o, current_user: current_user],
            is_nil(current_user.muted) or
              not fragment("(?).muted_filter_query @@ (?).search_vector", current_user, o)
          )
          |> select_merge([o, subscription: sub], %{
            user_subscribed?: not is_nil(sub.id)
          })

        _ ->
          q
          |> where([o], o.mature != true)
          |> select_merge(%{user_subscribed?: false})
      end

    q =
      case Keyword.fetch(opts, :current_user_member?) do
        {:ok, current_user_member?} ->
          q |> where([o], ^current_user_member? or o.hidden == false)

        :error ->
          q |> where([o], o.hidden == false)
      end

    q =
      case Keyword.fetch(opts, :order_by) do
        {:ok, nil} ->
          q

        {:ok, :index} ->
          q
          |> order_by([o], [fragment("CASE WHEN ? IS NULL THEN 1 ELSE 0 END", o.index), o.index])

        {:ok, :featured} ->
          q
          |> order_by([o, studio: s], [{:desc, o.inserted_at}, {:desc, s.inserted_at}])
          |> where([o], not is_nil(o.description) and o.description != "")
          |> where([o], not is_nil(o.card_img_id))
          |> where(
            [gallery_uploads: gallery_uploads],
            not is_nil(gallery_uploads.uploads) and
              fragment("array_length(?, 1) > 0", gallery_uploads.uploads)
          )

        {:ok, :oldest} ->
          q
          |> order_by([o], [{:asc, o.inserted_at}])

        {:ok, :newest} ->
          q
          |> order_by([o], [{:desc, o.inserted_at}])

        {:ok, :price_high} ->
          q
          |> order_by([default_prices: default_prices], desc: default_prices.sum)

        {:ok, :price_low} ->
          q
          |> order_by([default_prices: default_prices], asc: default_prices.sum)

        :error ->
          q
      end

    q =
      case Keyword.fetch(opts, :show_closed) do
        {:ok, true} ->
          q

        {:ok, _} ->
          q |> where([o], o.open == true)

        :error ->
          q |> where([o], o.open == true)
      end

    q =
      case Keyword.fetch(opts, :related_to) do
        {:ok, %Offering{} = related} ->
          q
          |> join(:inner, [o], rel in Offering,
            on: rel.id == ^related.id and rel.id != o.id,
            as: :related_to
          )
          |> where(
            [o, related_to: related_to],
            # TODO: Cache this db-side somehow? This seems like a lot of work
            # to be doing on the fly.
            fragment(
              "to_tsquery('banchan_fts', array_to_string(tsvector_to_array(?), ' | ')) @@ ?",
              related_to.search_vector,
              o.search_vector
            )
          )

        :error ->
          q
      end

    Repo.paginate(q,
      page: Keyword.get(opts, :page, 1),
      page_size: Keyword.get(opts, :page_size, 20)
    )
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

  def make_card_image!(%User{} = user, src, true, type, name) do
    # TODO: need two versions here, the smaller card image and "preview"
    # version for the offering page.
    upload = Uploads.save_file!(user, src, type, name)

    {:ok, card} =
      Thumbnailer.thumbnail(
        upload,
        dimensions: "1200",
        name: "card_image.jpg",
        callback: [__MODULE__.Notifications, :notify_images_updated]
      )

    card
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

  def make_gallery_image!(%User{} = user, src, true, type, name) do
    upload = Uploads.save_file!(user, src, type, name)

    {:ok, image} =
      Thumbnailer.thumbnail(
        upload,
        dimensions: "1200",
        name: "gallery_image.jpg",
        callback: [__MODULE__.Notifications, :notify_images_updated]
      )

    image
  end
end
