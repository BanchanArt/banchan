defmodule Banchan.Workers.Mailer do
  @moduledoc """
  Banchan's Oban worker for delivering emails quickly and reliably.
  """
  use Oban.Worker,
    queue: :mailers,
    unique: [period: 60],
    tags: ["mailer"]

  alias Banchan.Mailer

  @impl Oban.Worker
  def perform(%_{
        args: %{
          "to" => to,
          "subject" => subject,
          "html_body" => html_body,
          "text_body" => text_body
        }
      }) do
    Bamboo.Email.new_email(
      to: to,
      from:
        "notifications@" <>
          (Application.get_env(:banchan, Banchan.Mailer)[:sendgrid_domain] ||
             "noreply.banchan.art"),
      subject: subject,
      html_body: html_body,
      text_body: text_body
    )
    |> Mailer.deliver_now()
    |> case do
      {:ok, _} ->
        :ok

      {:ok, _, _} ->
        :ok

      {:error, err} ->
        {:error, err}
    end
  end

  def deliver(opts) do
    %{
      to: Keyword.fetch!(opts, :to),
      subject: Keyword.fetch!(opts, :subject),
      html_body: Keyword.fetch!(opts, :html_body),
      text_body: Keyword.get(opts, :text_body)
    }
    |> __MODULE__.new()
    |> Oban.insert()
  end
end
