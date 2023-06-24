defmodule Banchan.Studios do
  @moduledoc """
  The Studios context.
  """
  @dialyzer [
    {:nowarn_function, create_stripe_account: 2},
    :no_return
  ]

  import Ecto.Query, warn: false

  require Logger

  alias Banchan.Accounts
  alias Banchan.Accounts.User
  alias Banchan.Payments
  alias Banchan.Payments.Invoice
  alias Banchan.Repo

  alias Banchan.Studios.{
    Notifications,
    PortfolioImage,
    Studio,
    StudioBlock,
    StudioDisableHistory,
    StudioFollower
  }

  alias Banchan.Uploads
  alias Banchan.Uploads.Upload
  alias Banchan.Workers.{EnableStudio, Thumbnailer, UploadDeleter}

  use BanchanWeb, :verified_routes

  @host Application.compile_env!(:banchan, [BanchanWeb.Endpoint, :url, :host])

  ## Events

  @pubsub Banchan.PubSub

  @doc """
  Subscribes the current process to stripe state changes. This is used to
  live-update studio pages as the studio gets onboarded.
  """
  def subscribe_to_stripe_state(%Studio{stripe_id: stripe_id}) do
    Phoenix.PubSub.subscribe(@pubsub, "studio_stripe_state:#{stripe_id}")
  end

  @doc """
  Unsubscribes the current process from any further stripe state change events.
  """
  def unsubscribe_from_stripe_state(%Studio{stripe_id: stripe_id}) do
    Phoenix.PubSub.unsubscribe(@pubsub, "studio_stripe_state:#{stripe_id}")
  end

  ## Creation

  @doc """
  Creates a new studio. The new Studio must include a list of artists, who
  must all be confirmed user accounts. The new studio will be created but will
  need to be further onboarded before it can do its thing.

  The given artists will be automatically subscribed to Studio notifications.
  """
  def new_studio(%Studio{artists: artists} = studio, attrs) do
    if Enum.any?(artists, &is_nil(&1.confirmed_at)) do
      {:error, :unconfirmed_artist}
    else
      changeset = studio |> Studio.creation_changeset(attrs)

      changeset =
        if changeset.valid? do
          %{
            changeset
            | data: %{
                studio
                | stripe_id:
                    create_stripe_account(
                      url(~p"/studios/#{Ecto.Changeset.get_field(changeset, :handle)}"),
                      Ecto.Changeset.get_field(changeset, :country)
                    )
              }
          }
        else
          changeset
        end

      case changeset |> Repo.insert() do
        {:ok, studio} ->
          Repo.transaction(fn ->
            Enum.each(artists, &Notifications.subscribe_user!(&1, studio))
          end)

          {:ok, studio}

        {:error, err} ->
          {:error, err}
      end
    end
  end

  @doc """
  Gets a Stripe onboarding link for a Studio.
  """
  def get_onboarding_link!(%Studio{} = studio, return_url, refresh_url) do
    {:ok, link} =
      stripe_mod().create_account_link(%{
        account: studio.stripe_id,
        type: "account_onboarding",
        return_url: return_url,
        refresh_url: refresh_url
      })

    link.url
  end

  defp create_stripe_account(studio_url, country) do
    # NOTE: I don't know why dialyzer complains about this. It works just fine.
    {:ok, acct} =
      stripe_mod().create_account(%{
        type: "express",
        country: to_string(country),
        settings: %{payouts: %{schedule: %{interval: "manual"}}},
        capabilities: %{transfers: %{requested: true}},
        tos_acceptance: %{
          service_agreement:
            if country == :US do
              "full"
            else
              "recipient"
            end
        },
        business_profile: %{
          # Commercial Photograpy, Art, and Graphics
          mcc: "7333",
          # NB(zkat): This replacement is so this code will actually work in dev environments.
          url: String.replace(studio_url, "localhost:4000", "banchan.art")
        }
      })

    set_up_apple_pay!(acct)

    acct.id
  end

  @doc """
  Sets up Apple Pay for a connected account by setting its Apple Pay domain name.
  """
  def set_up_apple_pay!(account) do
    {:ok, _} =
      stripe_mod().create_apple_pay_domain(
        account.id,
        String.replace(@host, "localhost", "banchan.art")
      )

    :ok
  end

  @doc """
  Used by webhook to handle Stripe notifications for Studio account state changes.
  """
  def update_stripe_state!(account_id, account) do
    query = from(s in Studio, where: s.stripe_id == ^account_id)

    case query
         |> Repo.update_all(
           set: [
             stripe_charges_enabled: account.charges_enabled,
             stripe_details_submitted: account.details_submitted
           ]
         ) do
      {1, _} ->
        :ok

      {0, _} ->
        raise Ecto.NoResultsError, queryable: query
    end

    Phoenix.PubSub.broadcast!(
      @pubsub,
      "studio_stripe_state:#{account_id}",
      %Phoenix.Socket.Broadcast{
        topic: "studio_stripe_state:#{account_id}",
        event: "charges_state_changed",
        payload: account.charges_enabled
      }
    )

    Phoenix.PubSub.broadcast!(
      @pubsub,
      "studio_stripe_state:#{account_id}",
      %Phoenix.Socket.Broadcast{
        topic: "studio_stripe_state:#{account_id}",
        event: "details_submitted_changed",
        payload: account.details_submitted
      }
    )

    :ok
  end

  ## Getting/Listing

  @doc """
  Gets a studio by its handle.

  ## Examples

      iex> get_studio_by_handle!("foo")
      %Studio{}

      iex> get_studio_by_handle!("unknown")
      Exception Thrown

  """
  def get_studio_by_handle!(handle) when is_binary(handle) do
    from(s in Studio,
      where: s.handle == ^handle and is_nil(s.deleted_at)
    )
    |> Repo.one!()
    |> Repo.preload([:header_img, :card_img, :disable_info, :artists])
  end

  @doc """
  Fetches portfolio image uploads associated with this studio, in the order
  they've been arranged.
  """
  def studio_portfolio_uploads(%Studio{} = studio) do
    from(i in PortfolioImage,
      join: u in assoc(i, :upload),
      join: s in assoc(i, :studio),
      where: s.id == ^studio.id and is_nil(s.deleted_at),
      order_by: [asc: i.index],
      select: u
    )
    |> Repo.all()
  end

  @doc """
  Finds a studio card image's Upload.
  """
  def studio_card_img!(upload_id) do
    from(
      s in Studio,
      join: u in assoc(s, :card_img),
      where: u.id == ^upload_id and is_nil(s.deleted_at),
      select: u
    )
    |> Repo.one!()
  end

  @doc """
  Finds a studio header image's Upload.
  """
  def studio_header_img!(upload_id) do
    from(
      s in Studio,
      join: u in assoc(s, :header_img),
      where: u.id == ^upload_id and is_nil(s.deleted_at),
      select: u
    )
    |> Repo.one!()
  end

  @doc """
  Finds a studio portfolio image's Upload.
  """
  def studio_portfolio_img!(upload_id) do
    from(i in PortfolioImage,
      join: u in assoc(i, :upload),
      join: s in assoc(i, :studio),
      where: u.id == ^upload_id and is_nil(s.deleted_at),
      select: u
    )
    |> Repo.one!()
  end

  @doc """
  List members who are part of a studio

  ## Examples

      iex> list_studio_members(studio)
      [%User{}, %User{}, %User{}]
  """
  def list_studio_members(%Studio{} = studio) do
    Repo.all(Ecto.assoc(studio, :artists))
  end

  @doc """
  Über query for listing studios in various places across the site. Accepts
  several options that affect its behavior.

  ## Options

    * `:include_disabled?` - Whether to include disabled studios in the results.
    * `:include_own_archived?` - Whether to include archived studios if `:current_user` is a member.
    * `:with_member` - Filter studios to ones with this user as a member/artist.
    * `:current_user` - When given, applies various user-specific filters, like muted words, blocks, and mature content filtering.
    * `:include_pending?` - When true, includes studios that are pending.
    * `:query` - Webquery-style full text search applied to the Studio's search_vector.
    * `:order_by` - Applies some ordering/filtering to the results. Accepts the following values:
      * `:oldest` - Order by the oldest studios first.
      * `:newest` - Order by the newest studios first.
      * `:followers` - Order by the most followers first.
      * `:homepage` - Filter/order by homepage relevance.
      * `:featured` - Filter/order by whether a studio is marked as featured.
    * `:with_follower` - Filter studios to ones with this user as a follower.
    * `:page` - The page of results to return.
    * `:page_size` - How many results to return per page.
  """
  def list_studios(opts \\ []) do
    from(
      s in Studio,
      as: :studio,
      join: artist in assoc(s, :artists),
      as: :artist,
      where: is_nil(s.deleted_at),
      order_by: [desc: fragment("CASE WHEN (?).archived_at IS NULL THEN 1 ELSE 0 END", s)]
    )
    |> filter_include_disabled?(opts)
    |> filter_with_member(opts)
    |> filter_current_user(opts)
    |> filter_include_pending?(opts)
    |> filter_query(opts)
    |> filter_order_by(opts)
    |> filter_with_follower(opts)
    |> Repo.paginate(
      page_size: Keyword.get(opts, :page_size, 24),
      page: Keyword.get(opts, :page, 1)
    )
  end

  defp filter_include_disabled?(q, opts) do
    case Keyword.fetch(opts, :include_disabled?) do
      {:ok, true} ->
        q

      _ ->
        q
        |> join(:left, [studio: s], info in assoc(s, :disable_info), as: :disable_info)
        |> where([disable_info: info], is_nil(info.id))
    end
  end

  defp filter_with_member(q, opts) do
    case Keyword.fetch(opts, :with_member) do
      {:ok, %User{} = member} ->
        q
        |> where([artist: artist], artist.id == ^member.id)

      _ ->
        q
    end
  end

  # credo:disable-for-next-line Credo.Check.Refactor.CyclomaticComplexity
  defp filter_current_user(q, opts) do
    include_own_archived? = Keyword.get(opts, :include_own_archived?) == true

    case Keyword.fetch(opts, :current_user) do
      {:ok, %User{} = current_user} ->
        q
        |> join(:inner, [], user in User, on: user.id == ^current_user.id, as: :current_user)
        |> where(
          [s, current_user: current_user, artist: artist],
          s.mature != true or
            (s.mature == true and
               (current_user.mature_ok == true or :admin in current_user.roles or
                  :mod in current_user.roles or artist.id == current_user.id))
        )
        |> where(
          [studio: s, current_user: current_user, artist: artist],
          is_nil(s.archived_at) or
            :admin in current_user.roles or
            :mod in current_user.roles or
            (^include_own_archived? and artist.id == current_user.id)
        )
        |> where(
          [studio: s, current_user: current_user],
          is_nil(current_user.muted) or
            not fragment("(?).muted_filter_query @@ (?).search_vector", current_user, s)
        )
        |> join(:left, [studio: s], block in assoc(s, :blocklist), as: :blocklist)
        |> where(
          [blocklist: block, current_user: u],
          :admin in u.roles or :mod in u.roles or is_nil(block) or block.user_id != u.id
        )

      _ ->
        q
        |> where([s], s.mature != true and is_nil(s.archived_at))
    end
  end

  defp filter_include_pending?(q, opts) do
    case Keyword.fetch(opts, :include_pending?) do
      {:ok, true} ->
        q

      {:ok, false} ->
        q
        |> where([studio: s], s.stripe_charges_enabled == true)

      :error ->
        case Keyword.fetch(opts, :current_user) do
          {:ok, %User{} = user} ->
            q
            |> where(
              [studio: s, artist: a],
              s.stripe_charges_enabled == true or ^user.id == a.id
            )

          _ ->
            q
            |> where([studio: s], s.stripe_charges_enabled == true)
        end
    end
  end

  defp filter_query(q, opts) do
    case Keyword.fetch(opts, :query) do
      {:ok, nil} ->
        q

      {:ok, query} ->
        q
        |> where([s], fragment("websearch_to_tsquery(?) @@ (?).search_vector", ^query, s))

      :error ->
        q
    end
  end

  # credo:disable-for-next-line Credo.Check.Refactor.CyclomaticComplexity
  defp filter_order_by(q, opts) do
    case Keyword.fetch(opts, :order_by) do
      {:ok, nil} ->
        q

      {:ok, :oldest} ->
        q |> order_by([s], asc: s.inserted_at)

      {:ok, :newest} ->
        q |> order_by([s], desc: s.inserted_at)

      {:ok, :followers} ->
        q
        |> join(
          :left_lateral,
          [_s],
          followers in subquery(
            from follower in StudioFollower,
              where: parent_as(:studio).id == follower.studio_id,
              select: %{followers: count(follower)}
          ),
          as: :followers,
          on: true
        )
        |> order_by([followers: followers], desc: followers.followers)

      {:ok, :homepage} ->
        q
        |> order_by([s], desc: s.inserted_at)
        |> where([s], not is_nil(s.about) and s.about != "")
        |> where([s], not is_nil(s.card_img_id))

      {:ok, :featured} ->
        q
        |> order_by([s], desc: s.inserted_at)
        |> where([s], s.featured == true)
        |> where([s], not is_nil(s.header_img_id) or not is_nil(s.card_img_id))

      :error ->
        q
    end
  end

  defp filter_with_follower(q, opts) do
    case Keyword.fetch(opts, :with_follower) do
      {:ok, %User{} = follower} ->
        q
        |> join(:inner, [studio: s], follower in assoc(s, :followers), as: :follower)
        |> where([follower: f], f.id == ^follower.id)

      _ ->
        q
    end
  end

  @doc """
  Determine if a user is part of a studio.

  ## Examples

      iex> is_user_in_studio?(user, studio)
      true
  """
  def is_user_in_studio?(user, studio) when is_nil(user) or is_nil(studio), do: false

  def is_user_in_studio?(%User{id: user_id}, %Studio{id: studio_id}) do
    Repo.exists?(
      from us in "users_studios", where: us.user_id == ^user_id and us.studio_id == ^studio_id
    )
  end

  def user_blocked?(%Studio{} = studio, %User{} = user) do
    Repo.exists?(
      from sb in StudioBlock,
        join: u in assoc(sb, :user),
        where:
          sb.studio_id == ^studio.id and sb.user_id == ^user.id and :admin not in u.roles and
            :mod not in u.roles
    )
  end

  @doc """
  List of studios that `actor` is a member of that `user` is not already
  blocked from.
  """
  def blockable_studios(%User{} = actor, %User{} = user) do
    Repo.all(
      from s in Studio,
        join: u in assoc(s, :artists),
        left_join: sb in assoc(s, :blocklist),
        where:
          u.id == ^actor.id and (is_nil(sb) or sb.user_id != ^user.id) and is_nil(s.deleted_at)
    )
  end

  @doc """
  List of studios that `actor` is a member of that have blocked `user`.
  """
  def unblockable_studios(%User{} = actor, %User{} = user) do
    Repo.all(
      from s in Studio,
        join: u in assoc(s, :artists),
        left_join: sb in assoc(s, :blocklist),
        where: u.id == ^actor.id and sb.user_id == ^user.id and is_nil(s.deleted_at)
    )
  end

  @doc """
  Charges aren't enabled on a Studio until their Stripe account has gone
  through onboarding and been approved by Stripe. This will return true when
  that process has been completed.
  """
  def charges_enabled?(%Studio{} = studio, refresh \\ false) do
    if refresh do
      {:ok, acct} = stripe_mod().retrieve_account(studio.stripe_id)

      if acct.charges_enabled != studio.stripe_charges_enabled do
        update_stripe_state!(studio.stripe_id, acct)
      end

      acct.charges_enabled
    else
      studio.stripe_charges_enabled
    end
  end

  @doc """
  Fetches the private login link for a Studio to log into their Stripe Express
  dashboard.
  """
  def express_dashboard_link(%Studio{} = studio, redirect_url) do
    stripe_mod().create_login_link(
      studio.stripe_id,
      %{
        redirect_url: redirect_url
      }
    )
  end

  @doc """
  Returns the default currency for a studio. Takes into account global default.
  """
  def default_currency(nil), do: :USD
  def default_currency(%Studio{default_currency: default_currency}), do: default_currency

  ## Updating/Editing

  @doc """
  Updates the studio profile fields.
  """
  def update_studio_settings(%User{} = actor, %Studio{} = studio, attrs) do
    Ecto.Multi.new()
    |> Ecto.Multi.run(:checked_actor, fn _repo, _changes ->
      check_studio_member(studio, actor)
    end)
    |> Ecto.Multi.update(:updated_studio, Studio.settings_changeset(studio, attrs),
      returning: true
    )
    |> Repo.transaction()
    |> case do
      {:ok, %{updated_studio: studio}} ->
        {:ok, studio}

      {:error, _, error, _} ->
        {:error, error}
    end
  end

  @doc """
  Updates the studio profile fields.
  """
  # credo:disable-for-next-line Credo.Check.Refactor.CyclomaticComplexity
  def update_studio_profile(%User{} = actor, %Studio{} = studio, attrs) do
    Ecto.Multi.new()
    |> Ecto.Multi.run(:studio, fn _, _ ->
      {:ok, studio |> Repo.reload()}
    end)
    |> Ecto.Multi.run(:checked_actor, fn _repo, _changes ->
      check_studio_member(studio, actor)
    end)
    |> Ecto.Multi.run(:changeset, fn _repo, _changes ->
      changeset =
        studio
        |> Studio.profile_changeset(attrs)

      if changeset.valid? &&
           (Ecto.Changeset.fetch_change(changeset, :name) != :error ||
              Ecto.Changeset.fetch_change(changeset, :handle) != :error) do
        with {:ok, _} <-
               stripe_mod().update_account(studio.stripe_id, %{
                 business_profile: %{
                   name: Ecto.Changeset.get_field(changeset, :name),
                   url:
                     String.replace(
                       url(~p"/studios/#{Ecto.Changeset.get_field(changeset, :handle)}"),
                       "localhost:4000",
                       "banchan.art"
                     )
                 }
               }) do
          {:ok, changeset}
        end
      else
        {:ok, changeset}
      end
    end)
    |> Ecto.Multi.update(
      :updated_studio,
      fn %{changeset: changeset} ->
        changeset
      end,
      returning: true
    )
    |> Ecto.Multi.run(:remove_old_card_img, fn _, %{updated_studio: updated, studio: old} ->
      if old.card_img_id && old.card_img_id != updated.card_img_id do
        UploadDeleter.schedule_deletion(%Upload{id: old.card_img_id})
      else
        {:ok, nil}
      end
    end)
    |> Ecto.Multi.run(:remove_old_header_img, fn _, %{updated_studio: updated, studio: old} ->
      if old.header_img_id && old.header_img_id != updated.header_img_id do
        UploadDeleter.schedule_deletion(%Upload{id: old.header_img_id})
      else
        {:ok, nil}
      end
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{updated_studio: studio}} ->
        {:ok, studio}

      {:error, _, error, _} ->
        {:error, error}
    end
  end

  @doc """
  Saves a Studio's card image and schedules generation of its thumbnail.
  """
  def make_card_image!(%User{} = user, src, true, type, name) do
    upload = Uploads.save_file!(user, src, type, name)

    {:ok, card} =
      Thumbnailer.thumbnail(
        upload,
        dimensions: "600",
        name: "card_image.jpg"
      )

    card
  end

  @doc """
  Saves a Studio's header image and schedules generation of the header image
  as it will be displayed in the Studio page.
  """
  def make_header_image!(%User{} = user, src, true, type, name) do
    upload = Uploads.save_file!(user, src, type, name)

    {:ok, header} =
      Thumbnailer.thumbnail(
        upload,
        dimensions: "1200",
        name: "header_image.jpg"
      )

    header
  end

  @doc """
  Saves a porfolio image and schedules generation of its preview.
  """
  def make_portfolio_image!(%User{} = user, src, true, type, name) do
    upload = Uploads.save_file!(user, src, type, name)

    {:ok, image} =
      Thumbnailer.thumbnail(
        upload,
        dimensions: "1200",
        name: "portfolio_image.jpg"
      )

    image
  end

  @doc """
  Sets the portfolio images for a Studio.
  """
  def update_portfolio(%User{} = actor, %Studio{} = studio, portfolio_images) do
    Ecto.Multi.new()
    |> Ecto.Multi.run(:checked_actor, fn _repo, _changes ->
      check_studio_member(studio, actor)
    end)
    |> Ecto.Multi.update(
      :updated_studio,
      fn _ ->
        portfolio_images =
          (portfolio_images || [])
          |> Enum.with_index()
          |> Enum.map(fn {%Upload{} = upload, index} ->
            %PortfolioImage{
              index: index,
              upload_id: upload.id
            }
          end)

        studio
        |> Repo.preload(:portfolio_imgs)
        |> Studio.portfolio_changeset(portfolio_images)
      end,
      returning: true
    )
    |> Repo.transaction()
    |> case do
      {:ok, %{updated_studio: studio}} ->
        {:ok, studio}

      {:error, _, error, _} ->
        {:error, error}
    end
  end

  @doc """
  Updates whether the Studio is a featured studio. This is an admin action.
  """
  def update_featured(%User{} = actor, %Studio{} = studio, attrs) do
    Ecto.Multi.new()
    |> Ecto.Multi.run(:checked_actor, fn _repo, _changes ->
      actor = actor |> Repo.reload()

      if Accounts.admin?(actor) do
        {:ok, actor}
      else
        {:error, :unauthorized}
      end
    end)
    |> Ecto.Multi.update(:updated_studio, Studio.featured_changeset(studio, attrs),
      returning: true
    )
    |> Repo.transaction()
    |> case do
      {:ok, %{updated_studio: studio}} ->
        {:ok, studio}

      {:error, _, error, _} ->
        {:error, error}
    end
  end

  @doc """
  Disables a studio. This prevents the Studio and its Offerings from showing
  up in searches or being generally accessible. This Studio will no longer be
  able to accept commissions until the ban is lifted.

  An automatic unban may be scheduled, and Oban will take care of lifting it
  when the time comes.
  """
  def disable_studio(%User{} = actor, %Studio{} = studio, attrs) do
    Ecto.Multi.new()
    |> Ecto.Multi.run(:checked_actor, fn _repo, _changes ->
      actor = actor |> Repo.reload()

      if Accounts.mod?(actor) do
        {:ok, actor}
      else
        {:error, :unauthorized}
      end
    end)
    |> Ecto.Multi.run(:dummy_history, fn _repo, _changeset ->
      {:ok, %StudioDisableHistory{} |> StudioDisableHistory.disable_changeset(attrs)}
    end)
    |> Ecto.Multi.run(:unban_job, fn _repo, %{dummy_history: dummy} ->
      case Ecto.Changeset.fetch_change(dummy, :disabled_until) do
        {:ok, until} when not is_nil(until) ->
          EnableStudio.schedule_unban(studio, until)

        _ ->
          {:ok, nil}
      end
    end)
    |> Ecto.Multi.insert(:disable_history_entry, fn %{unban_job: job} ->
      %StudioDisableHistory{
        studio_id: studio.id,
        disabled_by_id: actor.id,
        disabled_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second),
        lifting_job_id: job && job.id
      }
      |> StudioDisableHistory.disable_changeset(attrs)
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{disable_history_entry: entry}} ->
        {:ok, entry}

      {:error, _, error, _} ->
        {:error, error}
    end
  end

  @doc """
  Re-enable a previously disabled studio.
  """
  # credo:disable-for-next-line Credo.Check.Refactor.CyclomaticComplexity
  def enable_studio(%User{} = actor, %Studio{} = studio, reason, cancel \\ true) do
    Ecto.Multi.new()
    |> Ecto.Multi.run(:checked_actor, fn _repo, _changes ->
      actor = actor |> Repo.reload()

      if Accounts.admin?(actor) || Accounts.system?(actor) do
        {:ok, actor}
      else
        {:error, :unauthorized}
      end
    end)
    |> Ecto.Multi.run(:changeset, fn _repo, _changes ->
      changeset =
        StudioDisableHistory.enable_changeset(%StudioDisableHistory{}, %{
          lifted_reason: reason
        })

      if changeset.valid? do
        {:ok, changeset}
      else
        {:error, changeset}
      end
    end)
    |> Ecto.Multi.update_all(
      :histories,
      fn _ ->
        lifted_at = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

        from(h in StudioDisableHistory,
          where: h.studio_id == ^studio.id and is_nil(h.lifted_at),
          select: h,
          update: [
            set: [
              lifted_at: ^lifted_at,
              lifted_by_id: ^actor.id,
              lifted_reason: ^reason
            ]
          ]
        )
      end,
      []
    )
    |> Ecto.Multi.run(:cancel_job, fn _repo, %{histories: {_, histories}} ->
      case histories do
        [history | _] ->
          if cancel do
            EnableStudio.cancel_unban(history)
            {:ok, nil}
          else
            {:ok, nil}
          end

        [] ->
          {:error, :not_disabled}
      end
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{histories: {_, [history | _]}}} ->
        {:ok, history}

      {:error, _, error, _} ->
        {:error, error}
    end
  end

  @doc """
  Updates admin-level fields for a user, such as their roles.
  """
  def update_admin_fields(%User{} = actor, %Studio{} = studio, attrs \\ %{}) do
    Ecto.Multi.new()
    |> Ecto.Multi.run(:checked_actor, fn _repo, _changes ->
      actor = actor |> Repo.reload()

      if Accounts.mod?(actor) do
        {:ok, actor}
      else
        {:error, :unauthorized}
      end
    end)
    |> Ecto.Multi.update(:updated_studio, Studio.admin_changeset(studio, attrs), returning: true)
    |> Repo.transaction()
    |> case do
      {:ok, %{updated_studio: studio}} ->
        {:ok, studio}

      {:error, _, error, _} ->
        {:error, error}
    end
  end

  @doc """
  Blocks a user from being able to interact with a Studio. The user will also
  be unable to further interact with commissions associated with this Studio,
  request new commissions, or even view the Studio profile.
  """
  def block_user(%User{} = actor, %Studio{} = studio, %User{} = user, attrs) do
    Ecto.Multi.new()
    |> Ecto.Multi.run(:checked_actor, fn _repo, _changes ->
      check_studio_member(studio, actor, [])
    end)
    |> Ecto.Multi.insert(
      :block,
      %StudioBlock{
        studio_id: studio.id,
        user_id: user.id
      }
      |> StudioBlock.changeset(attrs),
      on_conflict: {:replace, [:reason]},
      conflict_target: [:studio_id, :user_id]
    )
    |> Repo.transaction()
    |> case do
      {:ok, %{block: block}} ->
        {:ok, block}

      {:error, _, error, _} ->
        {:error, error}
    end
  end

  @doc """
  Unblocks a previously blocked user. This will allow them to interact with
  the Studio normally again.
  """
  def unblock_user(%User{} = actor, %Studio{} = studio, %User{} = user) do
    Ecto.Multi.new()
    |> Ecto.Multi.run(:checked_actor, fn _repo, _changes ->
      check_studio_member(studio, actor)
    end)
    |> Ecto.Multi.delete_all(
      :blocks,
      from(sb in StudioBlock,
        where: sb.studio_id == ^studio.id and sb.user_id == ^user.id
      )
    )
    |> Repo.transaction()
    |> case do
      {:ok, %{blocks: blocks}} ->
        {:ok, blocks}

      {:error, _, error, _} ->
        {:error, error}
    end
  end

  ## Deletion

  @doc """
  Archives a studio, removing it and its offerings from listings and
  preventing new commissions.
  """
  def archive_studio(%User{} = actor, %Studio{} = studio) do
    Ecto.Multi.new()
    |> Ecto.Multi.run(:checked_actor, fn _repo, _changes ->
      check_studio_member(studio, actor)
    end)
    |> Ecto.Multi.update(:updated_studio, Studio.archive_changeset(studio), returning: true)
    |> Repo.transaction()
    |> case do
      {:ok, %{updated_studio: studio}} ->
        {:ok, studio}

      {:error, _, error, _} ->
        {:error, error}
    end
  end

  @doc """
  Unarchives a studio.
  """
  def unarchive_studio(%User{} = actor, %Studio{} = studio) do
    Ecto.Multi.new()
    |> Ecto.Multi.run(:checked_actor, fn _repo, _changes ->
      check_studio_member(studio, actor)
    end)
    |> Ecto.Multi.update(:updated_studio, Studio.unarchive_changeset(studio), returning: true)
    |> Repo.transaction()
    |> case do
      {:ok, %{updated_studio: studio}} ->
        {:ok, studio}

      {:error, _, error, _} ->
        {:error, error}
    end
  end

  @doc """
  Soft-delete a Studio by marking it for deletion. It will be pruned in 30
  days.
  """
  def delete_studio(%User{} = actor, %Studio{} = studio, password) do
    Ecto.Multi.new()
    |> Ecto.Multi.run(:checked_actor, fn _repo, _changes ->
      with {:ok, actor} <- check_studio_member(studio, actor, [:system, :admin]),
           {:ok, _} <- check_password(actor, password) do
        {:ok, actor}
      end
    end)
    |> Ecto.Multi.run(:check_balance_empty, fn _repo, _changes ->
      # Precheck that all our balances are indeed empty.
      check_balance_empty(studio)
    end)
    |> Ecto.Multi.run(:cancel_invoices, fn _repo, %{checked_actor: actor} ->
      from(i in Invoice,
        join: c in assoc(i, :commission),
        where: c.studio_id == ^studio.id,
        where: i.status in [:pending, :submitted]
      )
      |> Repo.stream()
      |> Enum.reduce_while({:ok, []}, fn invoice, {:ok, acc} ->
        case Payments.expire_payment(actor, invoice) do
          {:ok, val} ->
            {:cont, {:ok, acc ++ [val]}}

          {:error, err} ->
            {:halt, {:error, err}}
        end
      end)
    end)
    |> Ecto.Multi.run(:check_balance_empty_again, fn _repo, _changes ->
      # Check balances again to clear up any races.
      check_balance_empty(studio)
    end)
    |> Ecto.Multi.run(:delete_stripe_account, fn _repo, _changes ->
      delete_stripe_account(studio)
    end)
    |> Ecto.Multi.update(:deleted_studio, Studio.deletion_changeset(studio), returning: true)
    |> Ecto.Multi.run(:notify_members, fn _repo,
                                          %{deleted_studio: studio, checked_actor: actor} ->
      {:ok, Notifications.studio_deleted(actor, studio)}
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{deleted_studio: studio}} ->
        {:ok, studio}

      {:error, _, error, _} ->
        {:error, error}
    end
  end

  defp check_balance_empty(%Studio{} = studio) do
    with {:ok, balance} <- Payments.get_banchan_balance(studio) do
      if has_balance?(balance.stripe_available) ||
           has_balance?(balance.stripe_pending) ||
           has_balance?(balance.held_back) ||
           has_balance?(balance.released) ||
           has_balance?(balance.on_the_way) ||
           has_balance?(balance.available) do
        {:error, :pending_funds}
      else
        {:ok, balance}
      end
    end
  end

  defp has_balance?(balance) do
    Enum.any?(balance, &(&1.amount > 0))
  end

  defp check_password(%User{} = user, password) do
    if (user.email && User.valid_password?(user, password)) || is_nil(user.email) do
      {:ok, user}
    else
      {:error, :invalid_password}
    end
  end

  defp delete_stripe_account(%Studio{} = studio) do
    stripe_mod().delete_account(studio.stripe_id)
  end

  @doc """
  Prunes all studios that were soft-deleted more than 30 days ago.

  Database constraints will take care of nilifying foreign keys or cascading
  deletions.
  """
  def prune_studios do
    now = NaiveDateTime.utc_now()

    Repo.transaction(fn ->
      from(
        s in Studio,
        where: not is_nil(s.deleted_at),
        where: s.deleted_at < datetime_add(^now, -30, "day")
      )
      |> Repo.stream()
      |> Enum.reduce(0, fn studio, acc ->
        # NB(@zkat): We hard match on `{:ok, _}` here because scheduling
        # deletions should really never fail.
        if studio.card_img_id do
          {:ok, _} = UploadDeleter.schedule_deletion(%Upload{id: studio.card_img_id})
        end

        if studio.header_img_id do
          {:ok, _} = UploadDeleter.schedule_deletion(%Upload{id: studio.header_img_id})
        end

        portfolio_imgs = Ecto.assoc(studio, :portfolio_imgs) |> Repo.all()

        if portfolio_imgs do
          portfolio_imgs
          # credo:disable-for-next-line Credo.Check.Refactor.Nesting
          |> Enum.each(fn %PortfolioImage{upload_id: upload_id} ->
            {:ok, _} = UploadDeleter.schedule_deletion(%Upload{id: upload_id})
          end)
        end

        case Repo.delete(studio) do
          {:ok, _} ->
            acc + 1

          {:error, error} ->
            Logger.error("Failed to prune studio #{studio.handle}: #{inspect(error)}")
            acc
        end
      end)
    end)
  end

  ## Misc utilities

  defp stripe_mod do
    Application.get_env(:banchan, :stripe_mod)
  end

  def check_studio_member(%Studio{} = studio, %User{} = actor, roles \\ [:system, :admin, :mod]) do
    actor = actor |> Repo.reload()

    if is_user_in_studio?(actor, studio) ||
         Enum.any?(roles, &(&1 in actor.roles)) do
      {:ok, actor}
    else
      {:error, :unauthorized}
    end
  end
end
