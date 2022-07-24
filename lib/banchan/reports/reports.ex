defmodule Banchan.Reports do
  @moduledoc """
  Context module for Banchan abuse reporting features.
  """

  import Ecto.Query, warn: false

  alias Banchan.Accounts.User
  alias Banchan.Repo
  alias Banchan.Reports.Report

  def new_report(%User{} = reporter, attrs) do
    %Report{reporter_id: reporter.id}
    |> Report.creation_changeset(attrs)
    |> Repo.insert()
  end

  def get_report_by_id!(id) when is_binary(id) do
    Repo.get!(Report, id) |> Repo.preload([:reporter, :investigator])
  end

  def update_report(%User{} = actor, %Report{} = report, attrs) do
    {:ok, ret} =
      Repo.transaction(fn ->
        actor = actor |> Repo.reload()

        if :admin in actor.roles || :mod in actor.roles do
          with {:ok, updated_report} <-
                 report
                 |> Report.update_changeset(attrs)
                 |> Repo.update(returning: true) do
            {:ok, updated_report |> Repo.preload([:reporter, :investigator], force: true)}
          end
        else
          {:error, :unauthorized}
        end
      end)

    ret
  end

  def assign_report(%User{} = actor, %Report{} = report, investigator) do
    {:ok, ret} =
      Repo.transaction(fn ->
        actor = actor |> Repo.reload()

        if :admin in actor.roles || :mod in actor.roles do
          with {:ok, updated_report} <-
                 report
                 |> Report.update_changeset(%{investigator_id: investigator && investigator.id})
                 |> Repo.update(returning: true) do
            {:ok, updated_report |> Repo.preload([:reporter, :investigator], force: true)}
          end
        else
          {:error, :unauthorized}
        end
      end)

    ret
  end

  # credo:disable-for-next-line Credo.Check.Refactor.CyclomaticComplexity
  def list_reports(%User{} = current_user, filter, opts \\ []) do
    q =
      from r in Report,
        as: :report,
        join: reporter in assoc(r, :reporter),
        as: :reporter,
        left_join: investigator in assoc(r, :investigator),
        as: :investigator,
        join: cu in User,
        as: :current_user,
        where: cu.id == ^current_user.id,
        where: :admin in cu.roles or :mod in cu.roles,
        select: r,
        select_merge: %{
          reporter: reporter,
          investigator: investigator
        }

    q = apply_filters(q, filter)

    Repo.paginate(q,
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
end
