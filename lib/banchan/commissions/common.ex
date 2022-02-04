defmodule Banchan.Commissions.Common do
  @moduledoc """
  This module exists for functions, usually used at compile time, that are
  used across the various `Banchan.Commissions` modules. It mainly exists to
  resolve compilation cycles.
  """
  @status_values [:submitted, :accepted, :in_progress, :paused, :waiting, :closed]

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

      :closed ->
        "Closed"
    end
  end
end
