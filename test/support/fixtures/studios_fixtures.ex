defmodule Banchan.StudiosFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Banchan.Studios` context.
  """
  @dialyzer [:no_return]

  import Mox

  alias Banchan.Studios
  alias Banchan.Studios.Studio

  def unique_stripe_id, do: "stripe-id#{System.unique_integer()}"
  def unique_studio_email, do: "studio#{System.unique_integer()}@example.com"
  def unique_studio_handle, do: "studio_#{:rand.uniform(100_000)}"
  def unique_studio_name, do: "studio name#{:rand.uniform(100_000)}"

  def valid_studio_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      name: unique_studio_name(),
      handle: unique_studio_handle(),
      country: "US",
      default_currency: "USD"
    })
  end

  defp stripe_account_mock do
    Banchan.StripeAPI.Mock
    |> expect(:create_account, fn _ ->
      {:ok, %Stripe.Account{id: "stripe-mock-id#{System.unique_integer()}"}}
    end)
    |> expect(:create_apple_pay_domain, fn _, _ ->
      {:ok, %{}}
    end)
  end

  def studio_fixture(artists, attrs \\ %{}) do
    stripe_account_mock()

    {:ok, studio} =
      Banchan.Studios.new_studio(
        %Studio{artists: artists},
        valid_studio_attributes(attrs)
      )

    studio
  end

  def enable_studio_charges!(studio) do
    Studios.update_stripe_state!(studio.stripe_id, %{
      charges_enabled: true,
      details_submitted: true
    })
  end
end
