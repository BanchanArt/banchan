defmodule Banchan.AccountsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Banchan.Accounts` context.
  """
  def unique_user_email, do: "user#{gen_random_string()}@example.com"
  def unique_user_handle, do: "user#{gen_random_string()}"
  def valid_user_password, do: "hello world!"

  def valid_user_attributes(attrs \\ %{}) do
    name = "user#{gen_random_string()}"
    handle = name <> "_hdl"
    email = name <> "@example.com"
    pw = valid_user_password()

    Enum.into(attrs, %{
      email: email,
      name: name,
      handle: handle,
      password: pw,
      password_confirmation: pw
    })
  end

  def user_fixture(attrs \\ %{}) do
    confirmed_at = NaiveDateTime.utc_now()

    {:ok, user} =
      attrs
      |> Enum.into(%{confirmed_at: confirmed_at})
      |> valid_user_attributes()
      |> Banchan.Accounts.register_user_test()

    user
  end

  def unconfirmed_user_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> valid_user_attributes()
      |> Banchan.Accounts.register_user_test()

    user
  end

  def oauth_user_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> valid_user_attributes()
      |> Banchan.Accounts.register_oauth_user_test()

    user
  end

  def extractable_user_token(token) do
    "[TOKEN]#{token}[TOKEN]"
  end

  def extract_user_token(text) do
    [_, token, _ | _] = String.split(text, "[TOKEN]")
    token
  end

  def gen_random_string(length \\ 5) do
    for _ <- 1..length, into: "", do: <<Enum.random(~c"0123456789abcdef")>>
  end
end
