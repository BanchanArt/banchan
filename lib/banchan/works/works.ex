defmodule Banchan.Works do
  @moduledoc """
  The Works context.
  """

  import Ecto.Query, warn: false
  alias Banchan.Repo

  alias Banchan.Accounts
  alias Banchan.Accounts.User
  alias Banchan.Commissions.Commission
  alias Banchan.Offerings.Offering
  alias Banchan.Studios
  alias Banchan.Studios.Studio
  alias Banchan.Uploads
  alias Banchan.Uploads.Upload
  alias Banchan.Workers.Thumbnailer
  alias Banchan.Works.{Work, WorkUpload}

  @public_id_size Work.rand_id() |> byte_size()

  ## Creation

  @doc """
  Creates a new `Work` under `studio`. `uploads` must be a non-empty list of
  `%Upload{}`s to be associated with the `Work`, in the order they are
  provided.

  ## Options

    * `:commission` - A commission to associate this `Work` with. Will also be
      used to set the `client_id` and `offering_id` for the `Work`, if
      present.
    * `:offering` - An offering to associate this `Work` with. This option is
      ignored if a given `:commission` has an existing `offering_id`, in which
      case that offering is used instead.
  """
  def new_work(%User{} = actor, %Studio{} = studio, attrs, uploads, opts \\ []) do
    {:ok, ret} =
      Repo.transaction(fn ->
        with {:ok, uploads} <-
               if(Enum.empty?(uploads), do: {:error, :uploads_required}, else: {:ok, uploads}),
             {:ok, _actor} <- Studios.check_studio_member(studio, actor) do
          work_uploads =
            uploads
            |> Enum.with_index()
            |> Enum.map(fn {%Upload{} = upload, index} ->
              preview_id =
                if Uploads.media?(upload) do
                  {:ok, %Upload{id: preview_id}} = Thumbnailer.thumbnail(upload)
                  preview_id
                end

              %WorkUpload{
                index: index,
                comment: "",
                upload_id: upload.id,
                preview_id: preview_id
              }
            end)

          commission = Keyword.get(opts, :commission)
          client_id = if(!is_nil(commission), do: commission.client_id)

          offering_id =
            if is_nil(commission) do
              Keyword.get(opts, :offering)
            else
              commission.offering_id
            end

          %Work{
            studio_id: studio.id,
            commission_id: commission && commission.id,
            client_id: client_id,
            offering_id: offering_id,
            uploads: work_uploads
          }
          |> Work.changeset(attrs)
          |> Repo.insert()
        end
      end)

    ret
  end

  ## Getting/Listing

  @doc """
  Über query for listing works across various use cases on the site. Accepts
  several options that affect its behavior.

  ## Options

    * `:page` - Page number to return results for. Defaults to 1.
    * `:page_size` - Number of results to return per page. Defaults to 20.
    * `:query` - Websearch-syntax search query used to match against the
      work's `search_vector`. Defaults to nil.
    * `:client` - Filter works only to those whose client is a given
      `%User{}`.
    * `:studio` - Filter works only to those belonging to the given
      `%Studio{}`.
    * `:offering` - Filter works only to those belonging to the given
      `%Offering{}`.
    * `:commission` - Filter works only to those belonging to the given
      `%Commission{}`.
    * `:current_user` - The current user. If given, it's used to:
      * Filter mature content based on the user's settings.
      * Filter works based on the user's muted word settings.
      * Remove works from studios that have blocked this user.
    * `:order_by` - The order to sort the offerings by. Some of these will
      also filter some offerings out.
      * `:featured` - Orders by the newest work/studio pair. Also filters out
        any works that don't have a decription.
      * `:oldest` - Show oldest works first.
      * `:newest` - Show newest works first.
    * `:related_to` - Accepts another `%Work{}` and returns works that are
      related to it. Defaults to nil.

  """
  def list_works(opts \\ []) do
    from(
      work in Work,
      as: :work
    )
    |> filter_query(opts)
    |> filter_current_user(opts)
    |> filter_studio(opts)
    |> filter_client(opts)
    |> filter_offering(opts)
    |> filter_commission(opts)
    |> filter_order_by(opts)
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

  defp filter_studio(q, opts) do
    case Keyword.fetch(opts, :studio) do
      {:ok, nil} ->
        q

      {:ok, %Studio{} = studio} ->
        q |> where([work: w], w.studio_id == ^studio.id)

      :error ->
        q
    end
  end

  defp filter_client(q, opts) do
    case Keyword.fetch(opts, :client) do
      {:ok, nil} ->
        q

      {:ok, %User{} = client} ->
        q |> where([work: w], w.client_id == ^client.id)

      :error ->
        q
    end
  end

  defp filter_offering(q, opts) do
    case Keyword.fetch(opts, :offering) do
      {:ok, nil} ->
        q

      {:ok, %Offering{} = offering} ->
        q |> where([work: w], w.offering_id == ^offering.id)

      :error ->
        q
    end
  end

  defp filter_commission(q, opts) do
    case Keyword.fetch(opts, :commission) do
      {:ok, nil} ->
        q

      {:ok, %Commission{} = commission} ->
        q |> where([work: w], w.commission_id == ^commission.id)

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
        |> join(:left, [work: w], studio in assoc(w, :studio), as: :studio)
        |> join(:left, [studio: studio], artist in assoc(studio, :artists), as: :artist)
        |> where(
          [
            work: w,
            current_user: current_user,
            artist: artist
          ],
          current_user == artist or
            w.mature != true or
            (w.mature == true and ^mature_content_enabled? == true and
               current_user.mature_ok == true)
        )
        |> where(
          [work: w, current_user: current_user, artist: artist],
          artist == current_user or w.client_id == current_user.id or w.private == false
        )
        |> where(
          [work: w, current_user: current_user, artist: artist],
          artist == current_user or is_nil(current_user.muted) or
            not fragment("(?).muted_filter_query @@ (?).search_vector", current_user, w)
        )
        |> join(:left, [studio: s], block in assoc(s, :blocklist), as: :blocklist)
        |> where(
          [blocklist: block, current_user: u, artist: artist],
          artist == u or :admin in u.roles or :mod in u.roles or is_nil(block) or
            block.user_id != u.id
        )

      _ ->
        q
        |> where([work: w], w.mature == false and w.private == false)
    end
  end

  # credo:disable-for-next-line Credo.Check.Refactor.CyclomaticComplexity
  defp filter_order_by(q, opts) do
    case Keyword.fetch(opts, :order_by) do
      {:ok, nil} ->
        q

      {:ok, :featured} ->
        order_seed = Keyword.get(opts, :order_seed, 77)

        q
        # TODO: make a function index to make this performant. It's probably fine for our current small sizes.
        |> order_by([work: w], [
          {:desc, fragment("extract(epoch from ?)::bigint % ?", w.inserted_at, ^order_seed)},
          {:asc, w.inserted_at}
        ])

      {:ok, :oldest} ->
        q
        |> order_by([o], [{:asc, o.inserted_at}])

      {:ok, :newest} ->
        q
        |> order_by([o], [{:desc, o.inserted_at}])

      :error ->
        q
    end
  end

  defp filter_related_to(q, opts) do
    case Keyword.fetch(opts, :related_to) do
      {:ok, %Work{} = related} ->
        q
        |> join(:inner, [work: w], rel in Work,
          on: rel.id == ^related.id and rel.id != w.id,
          as: :related_to
        )
        |> where(
          [work: w, related_to: related_to],
          fragment(
            "websearch_to_tsquery('banchan_fts', array_to_string(tsvector_to_array(?), ' OR ')) @@ ?",
            related_to.search_vector,
            w.search_vector
          )
        )

      :error ->
        q
    end
  end

  @doc """
  Gets a single work.

  Raises `Ecto.NoResultsError` if the Work does not exist.

  ## Examples

      iex> get_work!(123)
      %Work{}

      iex> get_work!(456)
      ** (Ecto.NoResultsError)

  """
  def get_work!(id), do: Repo.get!(Work, id) |> Repo.preload(:uploads)

  @doc """
  Gets a single work by its `public_id`. You may pass in a padded `public_id`
  with a `title` slug appended to it. It will simply be stripped.

  This function errors if the work does not exist, or if `user` is not allowed
  to access it.
  """
  def get_work_by_public_id_if_allowed!(studio, public_id, current_user)

  def get_work_by_public_id_if_allowed!(
        %Studio{} = studio,
        <<public_id::binary-size(@public_id_size), _>>,
        user
      ) do
    get_work_by_public_id_if_allowed!(studio, public_id, user)
  end

  def get_work_by_public_id_if_allowed!(
        %Studio{},
        <<public_id::binary-size(@public_id_size)>>,
        nil
      ) do
    from(
      work in Work,
      where: work.public_id == ^public_id and not work.private,
      select: work
    )
    |> Repo.one!()
    |> Repo.preload([:uploads, :studio, :offering, :commission, :client])
  end

  def get_work_by_public_id_if_allowed!(
        %Studio{id: studio_id},
        <<public_id::binary-size(@public_id_size)>>,
        %User{id: user_id}
      ) do
    from(
      work in Work,
      join: studio in assoc(work, :studio),
      join: artist in assoc(studio, :artists),
      join: current_user in User,
      on: current_user.id == ^user_id,
      where:
        work.public_id == ^public_id and
          work.studio_id == ^studio_id and
          (work.private == false or
             (not is_nil(work.client_id) and work.client_id == ^user_id) or
             artist.id == current_user.id or
             :admin in current_user.roles or
             :mod in current_user.roles),
      select: work
    )
    |> Repo.one!()
    |> Repo.preload([:uploads, :studio, :offering, :commission, :client])
  end

  @doc """
  Fetches a `WorkUpload`, but only if the given `User` is allowed access.
  """
  def get_work_upload_if_allowed!(work, upload_id, actor)
  def get_work_upload_if_allowed!(%Work{} = work, upload_id, nil) do
    from(
      work_upload in WorkUpload,
      join: work in assoc(work_upload, :work),
      where:
        work_upload.work_id == ^work.id and
          work_upload.upload_id == ^upload_id and
          not work.private,
      select: work_upload
    )
    |> Repo.one!()
    |> Repo.preload([:upload, :preview])
  end

  def get_work_upload_if_allowed!(%Work{} = work, upload_id, %User{id: user_id}) do
    from(
      work_upload in WorkUpload,
      join: work in assoc(work_upload, :work),
      join: studio in assoc(work, :studio),
      join: artist in assoc(studio, :artists),
      left_join: current_user in User,
      on: current_user.id == ^user_id,
      where:
        work_upload.work_id == ^work.id and
          work_upload.upload_id == ^upload_id and
          (work.private == false or
             (not is_nil(work.client_id) and work.client_id == ^user_id) or
             artist.id == ^user_id or
             :admin in current_user.roles or
             :mod in current_user.roles),
      select: work_upload
    )
    |> Repo.one!()
    |> Repo.preload([:upload, :preview])
  end

  @doc """
  Returns true if `actor` should be allowed to download a given work's
  original upload, instead of just having access to the previewd.
  """
  def can_download_uploads?(actor, work)
  def can_download_uploads?(actor, %Work{}) when is_nil(actor), do: false

  def can_download_uploads?(%User{id: user_id}, %Work{client_id: client_id})
      when not is_nil(user_id) and user_id == client_id,
      do: true

  def can_download_uploads?(%User{} = user, %Work{studio_id: studio_id}) do
    user = Repo.reload(user)
    Accounts.mod?(user) || Studios.is_user_in_studio?(user, %Studio{id: studio_id})
  end

  ## Updating

  def update_work(%Ecto.Changeset{} = changeset) do
    Repo.update(changeset)
  end

  ## TODO
end
