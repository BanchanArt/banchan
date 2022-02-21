defmodule Banchan.StudiosFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Banchan.Studios` context.
  """
  @dialyzer [:no_return]

  def unique_studio_name, do: "studio#{System.unique_integer()}"
  def unique_studio_handle, do: "studio#{System.unique_integer()}"

  def valid_studio_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      name: unique_studio_name(),
      handle: unique_studio_handle()
    })
  end

  def studio_fixture(studio, attrs \\ %{}) do
    {:ok, user} =
      Banchan.Accounts.register_admin(%{
        handle: "test-admin",
        email: "test@example.com",
        password: "foobarbazquux",
        password_confirmation: "foobarbazquux"
      })

    {:ok, studio} =
      Banchan.Studios.new_studio(
        user,
        %{studio | artists: [user]},
        "http://localhost:4000/studios/#{studio.handle}",
        valid_studio_attributes(attrs)
      )

    studio
  end
end
