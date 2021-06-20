defmodule Bespoke.Users do
  @moduledoc """
  Context module for Users
  """
  alias Bespoke.{Repo, Users.User}

  def set_roles(user, roles) do
    user
    |> User.changeset(%{roles: roles})
    |> Repo.update()
  end

  def has_role?(user, roles) when is_list(roles), do: Enum.any?(roles, &has_role?(user, &1))
  def has_role?(user, role) when is_atom(role), do: has_role?(user, Atom.to_string(role))
  def has_role?(%{roles: roles}, role), do: Enum.member?(roles, role)
end
