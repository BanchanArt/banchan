defmodule Banchan.Commissions.Common do
  @moduledoc """
  This module exists for functions, usually used at compile time, that are
  used across the various `Banchan.Commissions` modules. It mainly exists to
  resolve compilation cycles.
  """
  @status_values [
    :submitted,
    :accepted,
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

  def humanize_status(status) do
    case status do
      :submitted ->
        "Submitted"

      :accepted ->
        "Accepted"

      :paused ->
        "Paused"

      :in_progress ->
        "In Progress"

      :waiting ->
        "Waiting for Client"

      :ready_for_review ->
        "Ready for Review"

      :approved ->
        "Approved"

      :withdrawn ->
        "Withdrawn"
    end
  end

  def gen_public_id do
    random_string(10)
  end

  defp random_string(length) do
    :crypto.strong_rand_bytes(length) |> Base.url_encode64() |> binary_part(0, length)
  end
end
