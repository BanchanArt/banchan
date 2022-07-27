defmodule Banchan.Studios do
  @moduledoc """
  The Studios context.
  """
  @dialyzer [
    {:nowarn_function, create_stripe_account: 2},
    :no_return
  ]

  @pubsub Banchan.PubSub

  import Ecto.Query, warn: false
  require Logger

  alias Banchan.Accounts.User
  alias Banchan.Commissions.Invoice
  alias Banchan.Repo

  alias Banchan.Studios.{
    Notifications,
    Payout,
    PortfolioImage,
    Studio,
    StudioBlock,
    StudioDisableHistory,
    StudioFollower
  }

  alias Banchan.Uploads
  alias Banchan.Uploads.Upload
  alias Banchan.Workers.{EnableStudio, Thumbnailer}

  alias BanchanWeb.Endpoint
  alias BanchanWeb.Router.Helpers, as: Routes

  ## Events

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

  @doc """
  Subscribes the current process to payout-related events for this Studio.
  """
  def subscribe_to_payout_events(%Studio{} = studio) do
    Phoenix.PubSub.subscribe(@pubsub, "payout:#{studio.handle}")
  end

  @doc """
  Unsubscribes the current process from payout-related events for this Studio.
  """
  def unsubscribe_from_payout_events(%Studio{} = studio) do
    Phoenix.PubSub.unsubscribe(@pubsub, "payout:#{studio.handle}")
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
                      Routes.studio_shop_url(
                        Endpoint,
                        :show,
                        Ecto.Changeset.get_field(changeset, :handle)
                      ),
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

    acct.id
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
    Repo.get_by!(Studio, handle: handle) |> Repo.preload([:header_img, :card_img, :disable_info])
  end

  @doc """
  Fetches portfolio image uploads associated with this studio, in the order
  they've been arranged.
  """
  def studio_portfolio_uploads(%Studio{} = studio) do
    from(i in PortfolioImage,
      join: u in assoc(i, :upload),
      where: i.studio_id == ^studio.id,
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
      where: u.id == ^upload_id,
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
      where: u.id == ^upload_id,
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
      where: u.id == ^upload_id,
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
  """
  def list_studios(opts \\ []) do
    from(
      s in Studio,
      as: :studio,
      join: artist in assoc(s, :artists),
      as: :artist
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

  defp filter_current_user(q, opts) do
    case Keyword.fetch(opts, :current_user) do
      {:ok, %User{} = current_user} ->
        q
        |> where(
          [s],
          s.mature != true or (s.mature == true and ^current_user.mature_ok == true)
        )
        |> join(:inner, [], user in User, on: user.id == ^current_user.id, as: :current_user)
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

      _ ->
        q
        |> where([s], s.mature != true)
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
          as: :followers
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
        where: u.id == ^actor.id and (is_nil(sb) or sb.user_id != ^user.id)
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
        where: u.id == ^actor.id and sb.user_id == ^user.id
    )
  end

  @doc """
  Gets account balance stats for a studio, including how much is available on
  Stripe, how much has been released and available for payout, etc.
  """
  def get_banchan_balance!(%Studio{} = studio) do
    {:ok, stripe_balance} =
      stripe_mod().retrieve_balance(headers: %{"Stripe-Account" => studio.stripe_id})

    stripe_available =
      stripe_balance.available
      |> Enum.map(&Money.new(&1.amount, String.to_atom(String.upcase(&1.currency))))
      |> Enum.sort()

    stripe_pending =
      stripe_balance.pending
      |> Enum.map(&Money.new(&1.amount, String.to_atom(String.upcase(&1.currency))))
      |> Enum.sort()

    results =
      from(i in Invoice,
        join: c in assoc(i, :commission),
        left_join: p in assoc(i, :payouts),
        where:
          c.studio_id == ^studio.id and
            (i.status == :succeeded or i.status == :released),
        group_by: [
          fragment("CASE WHEN ? = 'pending' OR ? = 'in_transit' THEN 'on_the_way'
                  WHEN ? = 'paid' THEN 'paid'
                  WHEN ? = 'released' THEN 'released'
                  ELSE 'held_back'
                END", p.status, p.status, p.status, i.status),
          fragment("(?).currency", i.total_transferred)
        ],
        select: %{
          status:
            type(
              fragment("CASE WHEN ? = 'pending' OR ? = 'in_transit' THEN 'on_the_way'
                  WHEN ? = 'paid' THEN 'paid'
                  WHEN ? = 'released' THEN 'released'
                  ELSE 'held_back'
                END", p.status, p.status, p.status, i.status),
              :string
            ),
          final:
            type(
              fragment(
                "(sum((?).amount), (?).currency)",
                i.total_transferred,
                i.total_transferred
              ),
              Money.Ecto.Composite.Type
            )
        }
      )
      |> Repo.all()

    {released, held_back, on_the_way, paid} = get_net_values(results)

    available = get_released_available(stripe_available, released)

    %{
      stripe_available: stripe_available,
      stripe_pending: stripe_pending,
      held_back: held_back,
      released: released,
      on_the_way: on_the_way,
      paid: paid,
      available: available
    }
  end

  defp get_net_values(results) do
    Enum.reduce(results, {[], [], [], []}, fn %{status: status} = res,
                                              {released, held_back, on_the_way, paid} ->
      case status do
        "released" ->
          {[res.final | released], held_back, on_the_way, paid}

        "held_back" ->
          {released, [res.final | held_back], on_the_way, paid}

        "on_the_way" ->
          {released, held_back, [res.final | on_the_way], paid}

        "paid" ->
          {released, held_back, on_the_way, [res.final | paid]}
      end
    end)
  end

  defp get_released_available(stripe_available, released) do
    Enum.map(released, fn rel ->
      from_stripe =
        Enum.find(stripe_available, Money.new(0, rel.currency), &(&1.currency == rel.currency))

      cond do
        from_stripe.amount >= rel.amount ->
          rel

        from_stripe.amount < rel.amount ->
          from_stripe

        true ->
          Money.new(0, rel.currency)
      end
    end)
  end

  @doc """
  Gets a specific payout with its actor and invoices preloaded.
  """
  def get_payout!(public_id) when is_binary(public_id) do
    from(p in Payout,
      where: p.public_id == ^public_id,
      preload: [:actor, [invoices: [:commission, :event]]]
    )
    |> Repo.one!()
  end

  @doc """
  Paginated view of payouts for a studio.
  """
  def list_payouts(%Studio{} = studio, page \\ 1) do
    from(
      p in Payout,
      where: p.studio_id == ^studio.id,
      order_by: {:desc, p.inserted_at}
    )
    |> Repo.paginate(page: page, page_size: 10)
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

  ## Updating/Editing

  @doc """
  Updates the studio profile fields.
  """
  def update_studio_profile(actor, studio, current_user_member?, attrs)

  def update_studio_profile(%User{roles: roles} = actor, studio, false, attrs) do
    if :admin in roles || :mod in roles do
      update_studio_profile(actor, studio, true, attrs)
    else
      {:error, :unauthorized}
    end
  end

  def update_studio_profile(%User{} = actor, %Studio{} = studio, _, attrs) do
    {:ok, ret} =
      Repo.transaction(fn ->
        actor = Repo.reload(actor)

        if is_user_in_studio?(actor, studio) || :admin in actor.roles || :mod in actor.roles do
          changeset =
            studio
            |> Studio.profile_changeset(attrs)

          if changeset.valid? &&
               (Ecto.Changeset.fetch_change(changeset, :name) != :error ||
                  Ecto.Changeset.fetch_change(changeset, :handle) != :error) do
            {:ok, _} =
              stripe_mod().update_account(studio.stripe_id, %{
                business_profile: %{
                  name: Ecto.Changeset.get_field(changeset, :name),
                  url:
                    String.replace(
                      Routes.studio_shop_url(
                        Endpoint,
                        :show,
                        Ecto.Changeset.get_field(changeset, :handle)
                      ),
                      "localhost:4000",
                      "banchan.art"
                    )
                }
              })
          end

          changeset |> Repo.update(returning: true)
        else
          {:error, :unauthorized}
        end
      end)

    ret
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

    # TODO: Also generate a thumbnail?

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
  def update_portfolio(actor, studio, current_user_member?, portfolio_images)

  def update_portfolio(%User{} = actor, studio, false, images) do
    if :admin in actor.roles || :mod in actor.roles do
      update_portfolio(actor, studio, true, images)
    else
      {:error, :unauthorized}
    end
  end

  def update_portfolio(%User{} = actor, %Studio{} = studio, true, portfolio_images) do
    {:ok, ret} =
      Repo.transaction(fn ->
        actor = actor |> Repo.reload()

        if is_user_in_studio?(actor, studio) || :admin in actor.roles || :mod in actor.roles do
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
          |> Repo.update(returning: true)
        else
          {:error, :unauthorized}
        end
      end)

    ret
  end

  @doc """
  Updates whether the Studio is a featured studio. This is an admin action.
  """
  def update_featured(%User{} = actor, %Studio{} = studio, attrs) do
    {:ok, ret} =
      Repo.transaction(fn ->
        actor = actor |> Repo.reload()

        if :admin in actor.roles do
          studio
          |> Studio.featured_changeset(attrs)
          |> Repo.update()
        else
          {:error, :unauthorized}
        end
      end)

    ret
  end

  @doc """
  Disabled a studio. This prevents the Studio and its Offerings from showing
  up in searches or being generally accessible. This Studio will no longer be
  able to accept commissions until the ban is lifted.

  An automatic unban may be scheduled, and Oban will take care of lifting it
  when the time comes.
  """
  def disable_studio(%User{} = actor, %Studio{} = studio, attrs) do
    {:ok, ret} =
      Repo.transaction(fn ->
        actor = actor |> Repo.reload()

        if :admin in actor.roles || :mod in actor.roles do
          dummy = %StudioDisableHistory{} |> StudioDisableHistory.disable_changeset(attrs)

          with {:ok, job} <-
                 (case Ecto.Changeset.fetch_change(dummy, :disabled_until) do
                    {:ok, until} when not is_nil(until) ->
                      EnableStudio.schedule_unban(studio, until)

                    _ ->
                      {:ok, nil}
                  end) do
            %StudioDisableHistory{
              studio_id: studio.id,
              disabled_by_id: actor.id,
              disabled_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second),
              lifting_job_id: job && job.id
            }
            |> StudioDisableHistory.disable_changeset(attrs)
            |> Repo.insert()
          end
        else
          {:error, :unauthorized}
        end
      end)

    ret
  end

  @doc """
  Re-enable a previously disabled studio.
  """
  def enable_studio(actor, %Studio{} = studio, reason, cancel \\ true) do
    {:ok, ret} =
      Repo.transaction(fn ->
        actor = actor && actor |> Repo.reload()

        if is_nil(actor) || :admin in actor.roles || :mod in actor.roles do
          changeset =
            StudioDisableHistory.enable_changeset(%StudioDisableHistory{}, %{
              lifted_reason: reason
            })

          if changeset.valid? do
            {_, [history | _]} =
              Repo.update_all(
                from(h in StudioDisableHistory,
                  where: h.studio_id == ^studio.id and is_nil(h.lifted_at),
                  select: h
                ),
                set: [
                  lifted_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second),
                  lifted_by_id: actor && actor.id,
                  lifted_reason: reason
                ]
              )

            if cancel do
              EnableStudio.cancel_unban(history)
            end

            {:ok, history}
          else
            {:error, changeset}
          end
        else
          {:error, :unauthorized}
        end
      end)

    ret
  end

  @doc """
  Updates admin-level fields for a user, such as their roles.
  """
  def update_admin_fields(%User{} = actor, %Studio{} = studio, attrs \\ %{}) do
    {:ok, ret} =
      Repo.transaction(fn ->
        actor = actor |> Repo.reload()

        if :admin in actor.roles || :mod in actor.roles do
          Studio.admin_changeset(studio, attrs)
          |> Repo.update()
        else
          {:error, :unauthorized}
        end
      end)

    ret
  end

  @doc """
  Blocks a user from being able to interact with a Studio. The user will also
  be unable to further interact with commissions associated with this Studio,
  request new commissions, or even view the Studio profile.
  """
  def block_user(%User{} = actor, %Studio{} = studio, %User{} = user, attrs) do
    {:ok, ret} =
      Repo.transaction(fn ->
        if is_user_in_studio?(actor, studio) do
          %StudioBlock{
            studio_id: studio.id,
            user_id: user.id
          }
          |> StudioBlock.changeset(attrs)
          |> Repo.insert(
            on_conflict: {:replace, [:reason]},
            conflict_target: [:studio_id, :user_id]
          )
        else
          {:error, :unauthorized}
        end
      end)

    ret
  end

  @doc """
  Unblocks a previously blocked user. This will allow them to interact with
  the Studio normally again.
  """
  def unblock_user(%User{} = actor, %Studio{} = studio, %User{} = user) do
    {:ok, ret} =
      Repo.transaction(fn ->
        if is_user_in_studio?(actor, studio) do
          Repo.delete_all(
            from sb in StudioBlock,
              where: sb.studio_id == ^studio.id and sb.user_id == ^user.id
          )
        else
          {:error, :unauthorized}
        end
      end)

    ret
  end

  @doc """
  Pays out a Studio for the full available and released amount.
  """
  def payout_studio(%User{} = actor, %Studio{} = studio) do
    {:ok, balance} =
      stripe_mod().retrieve_balance(headers: %{"Stripe-Account" => studio.stripe_id})

    try do
      # TODO: notifications!
      {:ok,
       Enum.reduce(balance.available, [], fn avail, acc ->
         case payout_available!(actor, studio, avail) do
           {:ok, nil} ->
             acc

           {:ok, %Payout{} = payout} ->
             [payout | acc]
         end
       end)}
    catch
      %Stripe.Error{} = e ->
        Logger.error("Stripe error during payout: #{e.message}")
        {:error, e}

      {:error, err} ->
        Logger.error(%{message: "Internal error during payout", error: err})
        {:error, err}
    end
  end

  defp payout_available!(%User{} = actor, %Studio{} = studio, avail) do
    avail = Money.new(avail.amount, String.to_atom(String.upcase(avail.currency)))

    if avail.amount > 0 do
      {invoice_ids, invoice_count, total} = invoice_details(studio, avail)

      if total.amount > 0 do
        create_payout!(actor, studio, invoice_ids, invoice_count, total)
      else
        {:ok, nil}
      end
    else
      {:ok, nil}
    end
  end

  defp invoice_details(%Studio{} = studio, avail) do
    currency_str = Atom.to_string(avail.currency)
    now = NaiveDateTime.utc_now()

    from(i in Invoice,
      join: c in assoc(i, :commission),
      left_join: p in assoc(i, :payouts),
      where:
        c.studio_id == ^studio.id and i.status == :released and
          (is_nil(p.id) or p.status not in [:pending, :in_transit, :paid]) and
          fragment("(?).currency = ?::char(3)", i.total_transferred, ^currency_str) and
          i.payout_available_on < ^now,
      order_by: {:asc, i.updated_at}
    )
    |> Repo.all()
    |> Enum.reduce_while({[], 0, Money.new(0, avail.currency)}, fn invoice,
                                                                   {invoice_ids, invoice_count,
                                                                    total} = acc ->
      invoice_total = invoice.total_transferred

      if invoice_total.amount + total.amount > avail.amount do
        {:halt, acc}
      else
        {:cont, {[invoice.id | invoice_ids], invoice_count + 1, Money.add(total, invoice_total)}}
      end
    end)
  end

  defp create_payout!(
         %User{} = actor,
         %Studio{} = studio,
         invoice_ids,
         invoice_count,
         %Money{} = total
       ) do
    {:ok, ret} =
      Repo.transaction(fn ->
        case %Payout{
               amount: total,
               studio_id: studio.id,
               actor_id: actor.id,
               invoices: from(i in Invoice, where: i.id in ^invoice_ids) |> Repo.all()
             }
             |> Repo.insert(returning: [:id]) do
          {:ok, payout} ->
            payout = payout |> Repo.preload(:invoices)
            actual_count = Enum.count(payout.invoices)

            if actual_count == invoice_count do
              {:ok, payout}
            else
              Logger.error(%{
                message:
                  "Wrong number of invoices associated with new Payout (expected: #{invoice_count}, actual: ${actual_count}"
              })

              throw({:error, "Payout failed due to an internal error."})
            end

          {:error, err} ->
            Logger.error(%{message: "Failed to insert payout row into database", error: err})
            throw({:error, "Payout failed due to an internal error."})
        end
      end)

    case ret do
      {:ok, payout} ->
        case create_stripe_payout(studio, total) do
          {:ok, stripe_payout} ->
            process_payout_updated!(stripe_payout, payout.id)

          {:error, err} ->
            Logger.error(%{message: "Failed to create Stripe payout", error: err})

            process_payout_updated!(
              %Stripe.Payout{
                status: :failed,
                arrival_date: DateTime.utc_now() |> DateTime.to_unix()
              },
              payout.id
            )

            throw(err)
        end

      {:error, err} ->
        {:error, err}
    end
  end

  defp create_stripe_payout(%Studio{} = studio, %Money{} = total) do
    case stripe_mod().create_payout(
           %{
             amount: total.amount,
             currency: String.downcase(Atom.to_string(total.currency)),
             statement_descriptor: "banchan.art payout"
           },
           headers: %{"Stripe-Account" => studio.stripe_id}
         ) do
      {:ok, stripe_payout} ->
        {:ok, stripe_payout}

      {:error, %Stripe.Error{} = error} ->
        {:error, error}
    end
  end

  @doc """
  Cancels a pending payout.
  """
  def cancel_payout(%User{} = actor, %Studio{} = studio, payout_id) do
    if is_user_in_studio?(actor, studio) do
      case stripe_mod().cancel_payout(payout_id,
             headers: %{"Stripe-Account" => studio.stripe_id}
           ) do
        {:ok, %Stripe.Payout{id: ^payout_id, status: "canceled"}} ->
          # NOTE: db is updated on process_payout_updated, so we don't do it
          # here, particularly because we might not event have a payout entry in
          # our db at all (this function can get called when insertions fail).
          :ok

        {:error, %Stripe.Error{} = err} ->
          Logger.warn(%{
            message: "Failed to cancel payout #{payout_id}: #{err.message}",
            code: err.code
          })

          {:error, err}
      end
    else
      {:error, :unauthorized}
    end
  end

  @doc """
  Webhook handler for Stripe Payout state updates.
  """
  def process_payout_updated!(%Stripe.Payout{} = payout, id \\ nil) do
    query =
      cond do
        !is_nil(id) ->
          from(p in Payout, where: p.id == ^id, select: p)

        !is_nil(payout.id) ->
          from(p in Payout,
            where: p.stripe_payout_id == ^payout.id,
            select: p
          )

        true ->
          throw({:error, "Invalid process_payout_updated! call"})
      end

    case query
         |> Repo.update_all(
           set: [
             stripe_payout_id: payout.id,
             status: payout.status,
             failure_code: payout.failure_code,
             failure_message: payout.failure_message,
             arrival_date: payout.arrival_date |> DateTime.from_unix!() |> DateTime.to_naive(),
             method: payout.method,
             type: payout.type
           ]
         ) do
      {1, [payout]} ->
        Notifications.payout_updated(
          payout
          |> Repo.preload([:studio, :actor, [invoices: [:commission, :event]]])
        )

        {:ok, payout}

      {0, _} ->
        raise Ecto.NoResultsError, queryable: query
    end
  end

  defp stripe_mod do
    Application.get_env(:banchan, :stripe_mod)
  end
end
