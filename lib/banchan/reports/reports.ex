defmodule Banchan.Reports do
  @moduledoc """
  Context module for Banchan abuse reporting features.
  """

  import Ecto.Query, warn: false

  alias Banchan.Accounts
  alias Banchan.Accounts.User
  alias Banchan.Repo
  alias Banchan.Reports.Report

  ## Creation

  @doc """
  Creates a new abuse report.
  """
  def new_report(%User{} = reporter, attrs) do
    %Report{reporter_id: reporter.id}
    |> Report.creation_changeset(attrs)
    |> Repo.insert()
  end

  ## Getting/Listing

  @doc """
  Fetches a report by its binary id, preloading the reporter and investigator `%User{}` structs..
  """
  def get_report_by_id!(id) when is_binary(id) do
    Repo.get!(Report, id) |> Repo.preload([:reporter, :investigator])
  end

  @doc """
  Über query for listing reports.

  ## Filter

  `list_reports/3` expects a `%ReportFilter{}` as its second argument, which
  applies the following behaviors based on its field values:

    * `order_by` - How to order results. Defaults to `:default`. It can have
      the following values:
      * `:default` - Order by most recently updated.
      * `:newest` - Order by most recently created.
      * `:oldest` - Order by least recently created.
    * `query` - Websearch-syntax search query used to filter the report,
      based on its contents. Defaults to nil.
    * `statuses` - List of statuses to include. Defaults to showing reports with any status. An empty list is the same as `nil` (e.g. will show all).
    * `reporter` - Binary used to filter reports by matching reporter users.
    * `investigator` - Binary used to filter reports by matching current investigator users.

  ## Options

    * `:page` - Page number to return results for. Defaults to 1.
    * `:page_size` - Number of results to return per page. Defaults to 20.

  """
  def list_reports(%User{} = current_user, filter, opts \\ []) do
    from(r in Report,
      as: :report,
      join: reporter in assoc(r, :reporter),
      as: :reporter,
      left_join: investigator in assoc(r, :investigator),
      as: :investigator,
      join: cu in User,
      as: :current_user,
      on: true,
      where: cu.id == ^current_user.id,
      where: :admin in cu.roles or :mod in cu.roles,
      select: r,
      select_merge: %{
        reporter: reporter,
        investigator: investigator
      }
    )
    |> apply_filters(filter)
    |> Repo.paginate(
      page_size: Keyword.get(opts, :page_size, 24),
      page: Keyword.get(opts, :page, 1)
    )
  end

  defp apply_filters(q, filter) do
    q
    |> filter_order_by(filter)
    |> filter_query(filter)
    |> filter_statuses(filter)
    |> filter_reporter(filter)
    |> filter_investigator(filter)
  end

  defp filter_order_by(q, filter) do
    case filter.order_by do
      :newest ->
        q |> order_by([report: r], desc: r.inserted_at)

      :oldest ->
        q |> order_by([report: r], asc: r.inserted_at)

      :default ->
        q |> order_by([report: r], desc: r.updated_at)

      nil ->
        q |> order_by([report: r], desc: r.updated_at)
    end
  end

  defp filter_query(q, filter) do
    case filter.query do
      nil ->
        q

      "" ->
        q

      query when is_binary(query) ->
        q
        |> where(
          [report: r],
          fragment("websearch_to_tsquery(?) @@ (?).search_vector", ^query, r)
        )
    end
  end

  defp filter_statuses(q, filter) do
    case filter.statuses do
      nil ->
        q

      [] ->
        q

      statuses when is_list(statuses) ->
        q
        |> where([report: r], r.status in ^statuses)
    end
  end

  defp filter_reporter(q, filter) do
    case filter.reporter do
      nil ->
        q

      reporter when is_binary(reporter) ->
        q
        |> where(
          [reporter: reporter],
          fragment(
            "? @@ websearch_to_tsquery('banchan_fts', ?)",
            reporter.search_vector,
            ^reporter
          )
        )
    end
  end

  defp filter_investigator(q, filter) do
    case filter.investigator do
      nil ->
        q

      investigator when is_binary(investigator) ->
        q
        |> where(
          [investigator: investigator],
          fragment(
            "? @@ websearch_to_tsquery('banchan_fts', ?)",
            investigator.search_vector,
            ^investigator
          )
        )
    end
  end

  ## Updating/Editing

  @doc """
  Updates a report. Returns the updated report with `reporter` and `investigator` preloaded.
  """
  def update_report(%User{} = actor, %Report{} = report, attrs) do
    Ecto.Multi.new()
    |> Ecto.Multi.run(:checked_actor, fn _, _ ->
      actor = actor |> Repo.reload()

      if Accounts.mod?(actor) do
        {:ok, actor}
      else
        {:error, :unauthorized}
      end
    end)
    |> Ecto.Multi.update(:updated_report, Report.update_changeset(report, attrs), returning: true)
    |> Ecto.Multi.run(:final_report, fn _, %{updated_report: report} ->
      {:ok, report |> Repo.preload([:reporter, :investigator], force: true)}
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{final_report: report}} ->
        {:ok, report}

      {:error, _, error, _} ->
        {:error, error}
    end
  end

  @doc """
  Assigns a report to a particular user.
  """
  def assign_report(%User{} = actor, %Report{} = report, investigator) do
    Ecto.Multi.new()
    |> Ecto.Multi.run(:actor, fn _, _ ->
      actor = actor |> Repo.reload()

      if Accounts.mod?(actor) do
        {:ok, actor}
      else
        {:error, :unauthorized}
      end
    end)
    |> Ecto.Multi.run(:investigator, fn _, _ ->
      investigator = investigator && investigator |> Repo.reload()

      if investigator && !Accounts.mod?(actor) do
        {:error, :not_an_admin}
      else
        {:ok, investigator}
      end
    end)
    |> Ecto.Multi.update(
      :updated_report,
      fn %{investigator: investigator} ->
        Report.update_changeset(report, %{investigator_id: investigator && investigator.id})
      end,
      returning: true
    )
    |> Ecto.Multi.run(:final_report, fn _, %{updated_report: report} ->
      {:ok, report |> Repo.preload([:reporter, :investigator], force: true)}
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{final_report: report}} ->
        {:ok, report}

      {:error, _, error, _} ->
        {:error, error}
    end
  end

  ## GitHub

  @doc """
  File a bug on GitHub
  """
  def report_bug(%User{} = actor, title, body, bug?, actor_url_fn) do
    %{access_token: Application.fetch_env!(:banchan, :github_access_token)}
    |> Tentacat.Client.new()
    |> Tentacat.Issues.create("BanchanArt", "banchan", %{
      title: title,
      body: "reported by [@#{actor.handle}](#{actor_url_fn.(actor)}):\n\n#{body}",
      labels: ["feedback", "from-site" | if(bug?, do: ["bug"], else: [])]
    })
    |> case do
      {201, %{"html_url" => url}, _} ->
        {:ok, url}

      {_, _, _} ->
        {:error, :internal_error}
    end
  end
end
