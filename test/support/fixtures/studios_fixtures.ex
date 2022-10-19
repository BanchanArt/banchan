defmodule Banchan.StudiosFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Banchan.Studios` context.
  """
  @dialyzer [:no_return]

  import Hammox

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
      default_currency: "USD",
      payment_currencies: ["USD", "EUR", "JPY"]
    })
  end

  defp stripe_account_mock do
    Banchan.StripeAPI.Mock
    |> expect(:create_account, fn _ ->
      {:ok,
       %Stripe.Account{
         id: "stripe-mock-id#{System.unique_integer()}",
         charges_enabled: false,
         controller: %{},
         country: "US",
         default_currency: "USD",
         details_submitted: false,
         metadata: %{},
           object: "idk",
         type: "some type",
         external_accounts: %Stripe.List{
           data: [],
           has_more: false,
           object: "idk",
           total_count: nil,
           url: "url"
         }
       }}
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
end
