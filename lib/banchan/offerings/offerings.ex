defmodule Banchan.Offerings do
  @moduledoc """
  Main context module for Offerings.
  """
  import Ecto.Query, warn: false

  require Logger

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
  alias Banchan.Studios
  alias Banchan.Studios.Studio
  alias Banchan.Uploads
  alias Banchan.Uploads.Upload
  alias Banchan.Workers.{Thumbnailer, UploadDeleter}

  ## Creation

  @doc """
  Creates a new offering.
  """
  def new_offering(%User{} = actor, %Studio{} = studio, attrs, gallery_images) do
    {:ok, ret} =
      Repo.transaction(fn ->
        with {:ok, _actor} <- Studios.check_studio_member(studio, actor) do
          max_idx =
            from(o in Offering,
              where: o.studio_id == ^studio.id and is_nil(o.deleted_at),
              select: max(o.index)
            )
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
        end
      end)

    ret
  end

  ## Updating

  @doc """
  Creates an update changeset for an Offering.
  """
  def change_offering(%Offering{} = offering, attrs \\ %{}) do
    Offering.changeset(offering, attrs)
  end

  @doc """
  Updates offering details.
  """
  # credo:disable-for-next-line Credo.Check.Refactor.CyclomaticComplexity
  def update_offering(%User{} = actor, %Offering{} = offering, attrs, gallery_images) do
    Repo.transaction(fn ->
      with {:ok, _actor} <- Studios.check_studio_member(%Studio{id: offering.studio_id}, actor) do
        offering = Repo.reload(offering) |> Repo.preload([:options, :gallery_imgs])

        open_before? = Repo.one(from(o in Offering, where: o.id == ^offering.id, select: o.open))
        proposal_count = offering_proposal_count(offering)
        used_slots = offering_used_slots(offering, true)

        changeset =
          offering
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

        slots = Ecto.Changeset.get_field(changeset, :slots)
        max_proposals = Ecto.Changeset.get_field(changeset, :max_proposals)

        changeset =
          if (!is_nil(slots) && !is_nil(used_slots) && slots < used_slots) ||
               (!is_nil(max_proposals) && !is_nil(proposal_count) &&
                  max_proposals < proposal_count) do
            changeset
            |> Ecto.Changeset.put_change(:open, false)
          else
            changeset
          end

        old_uploads = offering.gallery_imgs |> Enum.map(& &1.upload_id)

        new_uploads =
          changeset |> Ecto.Changeset.get_field(:gallery_imgs, []) |> Enum.map(& &1.upload_id)

        drop_uploads =
          old_uploads
          |> Enum.filter(&(!Enum.member?(new_uploads, &1)))
          |> Enum.reduce_while({:ok, []}, fn upload_id, {:ok, acc} ->
            case UploadDeleter.schedule_deletion(%Upload{id: upload_id}) do
              {:ok, job} -> {:cont, {:ok, [job | acc]}}
              {:error, error} -> {:halt, {:error, error}}
            end
          end)

        drop_old_card_img =
          if offering.card_img_id &&
               offering.card_img_id != Ecto.Changeset.get_field(changeset, :card_img_id) do
            UploadDeleter.schedule_deletion(%Upload{id: offering.card_img_id})
          else
            {:ok, nil}
          end

        with {:ok, changed} <- changeset |> Repo.update(returning: true),
             {:ok, _} <- drop_old_card_img,
             {:ok, _jobs} <- drop_uploads do
          if !open_before? && changed.open do
            Notifications.offering_opened(changed)
          end

          if open_before? && !changed.open do
            Notifications.offering_closed(changed)
          end

          {:ok, changed}
        else
          {:error, error} ->
            Repo.rollback(error)
        end
      end
    end)
    |> case do
      {:ok, ret} -> ret
      {:error, error} -> {:error, error}
    end
  end

  @doc """
  Archives an offering. This removes it from the visible list of offerings for
  its studio and prevents new requests.
  """
  def archive_offering(actor, %Offering{} = offering) do
    {:ok, ret} =
      Repo.transaction(fn ->
        offering = offering |> Repo.reload()

        with {:ok, _actor} <- Studios.check_studio_member(%Studio{id: offering.studio_id}, actor) do
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

          {:ok, new}
        end
      end)

    ret
  end

  @doc """
  Unarchives an offering, making it available for new requests (if it's open).
  """
  def unarchive_offering(actor, %Offering{} = offering) do
    {:ok, ret} =
      Repo.transaction(fn ->
        offering = offering |> Repo.reload()

        with {:ok, _actor} <- Studios.check_studio_member(%Studio{id: offering.studio_id}, actor) do
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
        end
      end)

    ret
  end

  @doc """
  Changes the offering order in the Studio shop page. Does not affect ordering anywhere else.
  """
  # credo:disable-for-next-line Credo.Check.Refactor.CyclomaticComplexity
  def move_offering(actor, %Offering{} = offering, new_index) when new_index >= 0 do
    {:ok, ret} =
      Repo.transaction(fn ->
        with {:ok, _actor} <- Studios.check_studio_member(%Studio{id: offering.studio_id}, actor) do
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
                o.studio_id == ^offering.studio_id and not is_nil(o.index) and
                  o.index >= ^new_index,
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
        end
      end)

    ret
  end

  def make_card_image!(%User{} = user, %Studio{} = studio, src, type, name) do
    {:ok, user} = Studios.check_studio_member(studio, user)

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

  def make_gallery_image!(%User{} = user, %Studio{} = studio, src, type, name) do
    {:ok, user} = Studios.check_studio_member(studio, user)

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

  ## Getting/Listing

  @doc """
  Gets a Studio's offering by its type name. Includes preloaded gallery
  uploads ad number of used slots.

  If an actor is provided, it will be used to check whether the actor is a
  studio member and is able to see hidden offerings.
  """
  def get_offering_by_type!(actor, %Studio{} = studio, type) do
    q =
      from o in Offering,
        as: :offering,
        where: is_nil(o.deleted_at),
        join: s in assoc(o, :studio),
        as: :studio,
        where: is_nil(s.deleted_at) and is_nil(s.archived_at),
        left_lateral_join:
          gallery_uploads in subquery(
            from i in GalleryImage,
              where: i.offering_id == parent_as(:offering).id,
              join: u in assoc(i, :upload),
              group_by: [i.offering_id],
              select: %{uploads: fragment("array_agg(row_to_json(?))", u)}
          ),
        as: :gallery_uploads,
        on: true,
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
        on: true,
        where: o.studio_id == ^studio.id and o.type == ^type,
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
      if actor do
        q
        |> join(:inner, [], actor in User, as: :actor, on: actor.id == ^actor.id)
        |> join(:left, [studio: studio, actor: actor], us in "users_studios",
          as: :actor_member?,
          on: us.studio_id == studio.id and actor.id == us.user_id
        )
        |> where([offering: o, actor_member?: us], not is_nil(us) or not o.hidden)
        |> join(:left, [offering: o], sub in OfferingSubscription,
          on:
            sub.user_id == ^actor.id and sub.offering_id == o.id and
              sub.silenced != true,
          as: :subscribed
        )
        |> select_merge([subscribed: sub], %{
          user_subscribed?: not is_nil(sub.id)
        })
      else
        q
        |> where([offering: o], not o.hidden)
      end

    q
    |> Repo.one!()
    |> Repo.preload([:options, :studio, :card_img])
  end

  @doc """
  Calculates the offering's base price. Assumes the offering has been loaded
  through `list_offerings/1`, which populates the relevant virtual field.
  """
  def offering_base_price(%Offering{base_price: base_price}) do
    base_price
  end

  @doc """
  Does this offering have any optional addons?
  """
  def offering_has_addons?(%Offering{} = offering) do
    !is_nil(offering.options) &&
      !Enum.empty?(offering.options) &&
      offering.options
      |> Enum.any?(&(!&1.default))
  end

  @doc """
  Gets the currency for the offering, taking into account legacy offerings
  with null currency fields.
  """
  def offering_currency(%Offering{} = offering) do
    offering.currency ||
      (
        options = Repo.preload(offering, :options).options
        !Enum.empty?(options) && Enum.at(options, 0).price.currency
      ) ||
      from(
        s in Studio,
        where: s.id == ^offering.studio_id,
        select: s.default_currency
      )
      |> Repo.one!()
  end

  def offering_used_slots(%Offering{} = offering, reload \\ false) do
    if reload do
      from(c in Commission,
        where:
          c.offering_id == ^offering.id and
            c.status not in [:withdrawn, :approved, :submitted, :rejected],
        group_by: [c.offering_id],
        select: count(c.id)
      )
      |> Repo.one()
    else
      offering.used_slots
    end
  end

  def offering_proposal_count(%Offering{} = offering) do
    from(c in Commission,
      where:
        c.offering_id == ^offering.id and
          c.status == :submitted,
      group_by: [c.offering_id],
      select: count(c.id)
    )
    |> Repo.one()
  end

  @doc """
  Calculates the offering's available slots. If `reload` is false, this
  assumes the offering has been loaded through `list_offerings/1`, which
  populates the relevant virtual field.
  """
  def offering_available_slots(%Offering{} = offering, reload \\ false) do
    {slots, used_slots} =
      if reload do
        Repo.one(
          from o in Offering,
            left_join: c in assoc(o, :commissions),
            on: c.status not in [:withdrawn, :approved, :submitted, :rejected],
            join: s in assoc(o, :studio),
            where: o.id == ^offering.id and is_nil(o.deleted_at),
            where: is_nil(s.deleted_at) and is_nil(s.archived_at),
            group_by: [o.id, o.slots],
            select: {o.slots, count(c.id)}
        ) || {nil, 0}
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

  @doc """
  Calculates the offering's available pending proposals.
  """
  def offering_available_proposals(%Offering{} = offering) do
    {max, count} =
      Repo.one(
        from(o in Offering,
          left_join: c in assoc(o, :commissions),
          on: c.status == :submitted,
          join: s in assoc(o, :studio),
          where: o.id == ^offering.id and is_nil(o.deleted_at),
          where: is_nil(s.deleted_at) and is_nil(s.archived_at),
          group_by: [o.id, o.max_proposals],
          select: {o.max_proposals, count(c.id)}
        )
      ) || {nil, 0}

    cond do
      is_nil(max) ->
        nil

      count > max ->
        0

      true ->
        max - count
    end
  end

  @doc """
  Lists images for an offering's samples gallery, in the order they've been
  sorted into. Returns the Uploads themselves.
  """
  def offering_gallery_uploads(%Offering{} = offering) do
    from(i in GalleryImage,
      join: u in assoc(i, :upload),
      where: i.offering_id == ^offering.id,
      order_by: [asc: i.index],
      select: u
    )
    |> Repo.all()
  end

  @doc """
  Finds an offering card image's Upload.
  """
  def offering_card_img!(upload_id) do
    from(
      o in Offering,
      join: u in assoc(o, :card_img),
      where: u.id == ^upload_id and is_nil(o.deleted_at),
      select: u
    )
    |> Repo.one!()
  end

  @doc """
  Finds an offering header image's Upload.
  """
  def offering_header_img!(upload_id) do
    from(
      o in Offering,
      join: u in assoc(o, :header_img),
      where: u.id == ^upload_id and is_nil(o.deleted_at),
      select: u
    )
    |> Repo.one!()
  end

  @doc """
  Finds an offering gallery image's Upload.
  """
  def offering_gallery_img!(upload_id) do
    from(
      i in GalleryImage,
      join: o in assoc(i, :offering),
      join: u in assoc(i, :upload),
      where: u.id == ^upload_id and is_nil(o.deleted_at),
      select: u
    )
    |> Repo.one!()
  end

  @doc """
  Über query for listing offerings across various use cases on the site.
  Accepts several options that affect its behavior.

  ## Options

    * `:page` - Page number to return results for. Defaults to 1.
    * `:page_size` - Number of results to return per page. Defaults to 20.
    * `:include_pending?` - Whether to include offerings for studios whose charges
      are not enabled. Typically this is only a thing for testing and dealing
      with dev seeds. Defaults to false.
    * `:include_disabled?` - Whether to include offerings for disabled studios.
      Defaults to false.
    * `:include_archived?` - Whether to include archived offerings in the
      listing. Defaults to false.
    * `:query` - Websearch-syntax search query used to match against the
      offering's `search_vector`. Defaults to nil.
    * `:studio` - Filter offerings only to those belonging to the given
      `%Studio{}`.
    * `:current_user` - The current user. If given, it's used to:
      * Filter mature content based on the user's settings.
      * Filter offerings based on the user's muted word settings.
      * Remove offerings from studios that have blocked this user.
      * Populate the `user_subscribed?` field based on the user's settings.
    * `:order_by` - The order to sort the offerings by. Some of these will
      also filter some offerings out.
      * `:index` - Sort by the offering's index in its Studio shop.
      * `:featured` - Orders by the newest offerings/studio pair. Also filters
        out any offerings that don't have all of: a decription, card image,
        and gallery images.
      * `:oldest` - Show oldest offerings first.
      * `:newest` - Show newest offerings first.
      * `:price_high` - Show highest-priced offerings first.
      * `:price_low` - Show lowest-priced offerings first.
    * `:include_closed?` - Whether to show closed offerings. Defaults to false.
    * `:related_to` - Accepts another `%Offering{}` and returns offerings that
      are related to it. Defaults to nil.

  """
  def list_offerings(opts \\ []) do
    from(o in Offering,
      as: :offering,
      join: s in assoc(o, :studio),
      as: :studio,
      where: is_nil(o.deleted_at) and is_nil(s.deleted_at) and is_nil(s.archived_at),
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
      on: true,
      left_lateral_join:
        price_info in subquery(
          from oo in OfferingOption,
            where: oo.offering_id == parent_as(:offering).id,
            group_by: [oo.offering_id],
            select: %{
              has_addons:
                fragment("max(case when ? = true then 0 else 1 end)::boolean", oo.default),
              base_price:
                type(
                  fragment(
                    "(sum(case when ? then (?).amount else 0 end), min((?).currency))",
                    oo.default,
                    oo.price,
                    oo.price
                  ),
                  Money.Ecto.Composite.Type
                )
            }
        ),
      as: :price_info,
      on: true,
      left_lateral_join:
        gallery_uploads in subquery(
          from i in GalleryImage,
            where: i.offering_id == parent_as(:offering).id,
            join: u in assoc(i, :upload),
            group_by: [i.offering_id],
            select: %{uploads: fragment("array_agg(row_to_json(?))", u)}
        ),
      as: :gallery_uploads,
      on: true,
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
          has_addons: price_info.has_addons,
          base_price: type(price_info.base_price, Money.Ecto.Composite.Type)
        })
    )
    |> filter_query(opts)
    |> filter_include_pending?(opts)
    |> filter_include_disabled?(opts)
    |> filter_include_archived?(opts)
    |> filter_studio(opts)
    |> filter_current_user(opts)
    |> filter_order_by(opts)
    |> filter_include_closed?(opts)
    |> filter_related_to(opts)
    |> Repo.paginate(
      page: Keyword.get(opts, :page, 1),
      page_size: Keyword.get(opts, :page_size, 20)
    )
  end

  defp filter_query(q, opts) do
    case Keyword.fetch(opts, :query) do
      {:ok, nil} ->
        q

      {:ok, query} ->
        q
        |> where([o], fragment("websearch_to_tsquery(?) @@ (?).search_vector", ^query, o))

      :error ->
        q
    end
  end

  defp filter_include_pending?(q, opts) do
    case Keyword.fetch(opts, :include_pending?) do
      {:ok, true} ->
        q

      _ ->
        q
        |> where([studio: s], s.stripe_charges_enabled == true)
    end
  end

  defp filter_include_disabled?(q, opts) do
    case Keyword.fetch(opts, :include_disabled?) do
      {:ok, true} ->
        q

      _ ->
        q
        |> join(:left, [studio: s], disable_info in assoc(s, :disable_info), as: :disable_info)
        |> where([disable_info: disable_info], is_nil(disable_info))
    end
  end

  defp filter_include_archived?(q, opts) do
    case Keyword.fetch(opts, :include_archived?) do
      {:ok, true} ->
        q

      _ ->
        q |> where([o], is_nil(o.archived_at))
    end
  end

  defp filter_studio(q, opts) do
    case Keyword.fetch(opts, :studio) do
      {:ok, nil} ->
        q

      {:ok, %Studio{} = studio} ->
        q |> where([o], o.studio_id == ^studio.id)

      :error ->
        q
    end
  end

  # credo:disable-for-next-line Credo.Check.Refactor.CyclomaticComplexity
  defp filter_current_user(q, opts) do
    mature_content_enabled? = Application.get_env(:banchan, :mature_content_enabled?, false)

    case Keyword.fetch(opts, :current_user) do
      {:ok, %User{} = current_user} ->
        q
        |> join(:inner, [], user in User, on: user.id == ^current_user.id, as: :current_user)
        |> join(:left, [studio: studio, current_user: current_user], us in "users_studios",
          as: :current_user_member?,
          on: us.studio_id == studio.id and current_user.id == us.user_id
        )
        |> where(
          [
            studio: s,
            offering: o,
            current_user: current_user,
            current_user_member?: current_user_member?
          ],
          not is_nil(current_user_member?) or
            o.mature != true or
            ((s.mature == true or o.mature == true) and ^mature_content_enabled? == true and
               current_user.mature_ok == true)
        )
        |> where(
          [offering: o, current_user_member?: current_user_member?],
          not is_nil(current_user_member?) or o.hidden == false
        )
        |> join(:left, [offering: o, current_user: current_user], sub in OfferingSubscription,
          on:
            sub.user_id == current_user.id and sub.offering_id == o.id and
              sub.silenced != true,
          as: :subscription
        )
        |> where(
          [o, current_user: current_user],
          is_nil(current_user.muted) or
            not fragment("(?).muted_filter_query @@ (?).search_vector", current_user, o)
        )
        |> join(:left, [studio: s], block in assoc(s, :blocklist), as: :blocklist)
        |> where(
          [blocklist: block, current_user: u],
          :admin in u.roles or :mod in u.roles or is_nil(block) or block.user_id != u.id
        )
        |> select_merge([o, subscription: sub], %{
          user_subscribed?: not is_nil(sub.id)
        })

      _ ->
        q
        |> where([o, studio: s], s.mature != true and o.mature != true and o.hidden == false)
        |> select_merge(%{user_subscribed?: false})
    end
  end

  # credo:disable-for-next-line Credo.Check.Refactor.CyclomaticComplexity
  defp filter_order_by(q, opts) do
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
  end

  defp filter_include_closed?(q, opts) do
    case Keyword.fetch(opts, :include_closed?) do
      {:ok, true} ->
        q

      {:ok, _} ->
        q |> where([o], o.open == true)

      :error ->
        q |> where([o], o.open == true)
    end
  end

  defp filter_related_to(q, opts) do
    case Keyword.fetch(opts, :related_to) do
      {:ok, %Offering{} = related} ->
        q
        |> join(:inner, [o], rel in Offering,
          on: rel.id == ^related.id and rel.id != o.id,
          as: :related_to
        )
        |> where(
          [o, related_to: related_to],
          fragment(
            "to_tsquery('banchan_fts', array_to_string(tsvector_to_array(?), ' | ')) @@ ?",
            related_to.search_vector,
            o.search_vector
          )
        )

      :error ->
        q
    end
  end

  ## Deletion

  @doc """
  Soft-deletes an offering by marking it for deletion. It will be pruned in 30
  days.
  """
  def delete_offering(%User{} = actor, %Offering{} = offering) do
    {:ok, ret} =
      Repo.transaction(fn ->
        with {:ok, _} <- Studios.check_studio_member(%Studio{id: offering.studio_id}, actor),
             # NB(@zkat): We archive the offering first because this takes
             # care of updating offering order indices. It's a hack but hey it
             # does the job.
             {:ok, offering} <- archive_offering(actor, offering),
             {:ok, _} <- delete_gallery_imgs(offering),
             {:ok, _} <- delete_card_img(offering) do
          offering
          |> Offering.deletion_changeset()
          |> Repo.update(returning: true)
        end
      end)

    ret
  end

  defp delete_gallery_imgs(%Offering{} = offering) do
    offering = offering |> Repo.preload(:gallery_imgs)

    offering.gallery_imgs
    |> Enum.reduce_while({:ok, []}, fn %GalleryImage{upload_id: upload_id}, {:ok, acc} ->
      case UploadDeleter.schedule_deletion(%Upload{id: upload_id}) do
        {:ok, _} ->
          {:cont, {:ok, [upload_id | acc]}}

        {:error, error} ->
          {:halt, {:error, error}}
      end
    end)
  end

  defp delete_card_img(%Offering{card_img_id: upload_id}) do
    if upload_id do
      UploadDeleter.schedule_deletion(%Upload{id: upload_id})
    else
      {:ok, nil}
    end
  end

  @doc """
  Prunes all offerings that were soft-deleted more than 30 days ago.

  Database constraints will take care of nilifying foreign keys or cascading
  deletions.
  """
  def prune_offerings do
    now = NaiveDateTime.utc_now()

    Repo.transaction(fn ->
      from(
        o in Offering,
        where: not is_nil(o.deleted_at),
        where: o.deleted_at < datetime_add(^now, -30, "day")
      )
      |> Repo.stream()
      |> Enum.reduce(0, fn off, acc ->
        # NB(@zkat): We hard match on `{:ok, _}` here because scheduling
        # deletions should really never fail.

        gallery_imgs = Ecto.assoc(off, :gallery_imgs) |> Repo.all()

        if gallery_imgs do
          gallery_imgs
          # credo:disable-for-next-line Credo.Check.Refactor.Nesting
          |> Enum.each(fn %GalleryImage{upload_id: upload_id} ->
            {:ok, _} = UploadDeleter.schedule_deletion(%Upload{id: upload_id})
          end)
        end

        if off.card_img_id do
          {:ok, _} = UploadDeleter.schedule_deletion(%Upload{id: off.card_img_id})
        end

        case Repo.delete(off) do
          {:ok, _} ->
            acc + 1

          {:error, error} ->
            Logger.error("Failed to prune offering #{off.id}: #{inspect(error)}")
            acc
        end
      end)
    end)
  end
end
