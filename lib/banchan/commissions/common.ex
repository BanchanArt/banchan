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

  @doc """
  List of possible commission statuses.
  """
  def status_values do
    @status_values
  end

  @event_types [
    # No added/edited/removed variant because these are mutable.
    :comment,
    :line_item_added,
    :line_item_removed,
    :payment_processed,
    :refund_processed,
    :status,
    :title_changed
  ]

  @doc """
  List of possible commission event types.
  """
  def event_types do
    @event_types
  end

  @doc """
  Converts a commission status enum value to its human-consumable string.
  """
  def humanize_status(:submitted), do: "Submitted"
  def humanize_status(:accepted), do: "Accepted"
  def humanize_status(:rejected), do: "Rejected"
  def humanize_status(:paused), do: "Paused"
  def humanize_status(:in_progress), do: "In Progress"
  def humanize_status(:waiting), do: "Waiting"
  def humanize_status(:ready_for_review), do: "Final Review"
  def humanize_status(:approved), do: "Approved"
  def humanize_status(:withdrawn), do: "Withdrawn"

  @doc """
  Description of a commission status.
  """
  def status_description(:submitted),
    do: "The commission has been submitted to the studio and is awaiting acceptance."

  def status_description(:accepted),
    do: "The commission has been accepted by the studio and work will begin soon."

  def status_description(:rejected),
    do: "The studio has decided to reject this commission request."

  def status_description(:paused),
    do: "The studio has paused work on this commission temporarily."

  def status_description(:in_progress), do: "The studio is actively working on this commission."

  def status_description(:waiting),
    do: "The studio is waiting for a response from the client before continuing work."

  def status_description(:ready_for_review), do: "The studio is waiting for a final review."

  def status_description(:approved),
    do:
      "The commission has received final approval and all payments and attachments have been released."

  def status_description(:withdrawn),
    do: "The client has withdrawn this commission. It is now closed."

  @doc """
  Generates a new public_id for a commission.
  """
  def gen_public_id do
    random_string(10)
  end

  defp random_string(length) do
    :crypto.strong_rand_bytes(length) |> Base.url_encode64() |> binary_part(0, length)
  end
end
