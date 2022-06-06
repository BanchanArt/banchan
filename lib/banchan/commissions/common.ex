defmodule Banchan.Commissions.Common do
  @moduledoc """
  This module exists for functions, usually used at compile time, that are
  used across the various `Banchan.Commissions` modules. It mainly exists to
  resolve compilation cycles.
  """
  @status_values [
    :submitted,
    :accepted,
    :rejected,
    :in_progress,
    :paused,
    :waiting,
    :ready_for_review,
    :approved,
    :withdrawn
  ]

  def status_values do
    @status_values
  end

  @event_types [
    # No added/edited/removed variant because these are mutable.
    :comment,
    :line_item_added,
    :line_item_removed,
    :payment_processed,
    :status
  ]

  def event_types do
    @event_types
  end

  def humanize_status(:submitted), do: "Submitted"
  def humanize_status(:accepted), do: "Accepted"
  def humanize_status(:rejected), do: "Rejected"
  def humanize_status(:paused), do: "Paused"
  def humanize_status(:in_progress), do: "In Progress"
  def humanize_status(:waiting), do: "Waiting for Client"
  def humanize_status(:ready_for_review), do: "Ready for Review"
  def humanize_status(:approved), do: "Approved"
  def humanize_status(:withdrawn), do: "Withdrawn"

  def gen_public_id do
    random_string(10)
  end

  defp random_string(length) do
    :crypto.strong_rand_bytes(length) |> Base.url_encode64() |> binary_part(0, length)
  end
end
