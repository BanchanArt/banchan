defmodule Banchan.StudiosFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Banchan.Studios` context.
  """
  @dialyzer [:no_return]

  import Mox

  def unique_studio_name, do: "studio#{System.unique_integer()}"
  def unique_studio_handle, do: "studio#{System.unique_integer()}"
  def unique_stripe_id, do: "mock_stripe_id#{System.unique_integer()}"

  def valid_studio_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      name: unique_studio_name(),
      handle: unique_studio_handle()
    })
  end

  defp stripe_account_mock() do
    Banchan.StripeAPI.Mock
    |> expect(:create_account, fn _ ->
      {:ok, %Stripe.Account{id: unique_stripe_id()}}
    end)
  end

  def studio_fixture(studio, attrs \\ %{}) do
    {:ok, user} =
      Banchan.Accounts.register_admin(%{
        handle: "test-admin",
        email: "test@example.com",
        password: "foobarbazquux",
        password_confirmation: "foobarbazquux"
      })

    stripe_account_mock()

    {:ok, studio} =
      Banchan.Studios.new_studio(
        %{studio | artists: [user]},
        "http://localhost:4000/studios/#{studio.handle}",
        valid_studio_attributes(attrs)
      )

    studio
  end
end
