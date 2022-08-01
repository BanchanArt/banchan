defmodule Banchan.AccountsTest.Admin do
  @moduledoc """
  Tests for admin-related Accounts operations.
  """
  use Banchan.DataCase, async: true

  import Banchan.AccountsFixtures

  alias Banchan.Accounts
  alias Banchan.Accounts.{DisableHistory, User}

  describe "disable_user/3" do
    test "Adds a DisableHistory entry to the user if actor is an admin or a mod" do
      admin = user_fixture(%{roles: [:admin]})
      user = user_fixture()

      assert {:ok, %DisableHistory{} = history} =
               Accounts.disable_user(admin, user, %{
                 disabled_reason: "bad actor"
               })

      assert history.user_id == user.id
      assert history.disabled_by_id == admin.id
      assert history.disabled_reason == "bad actor"
      assert is_nil(history.disabled_until)

      now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

      diff = now |> NaiveDateTime.diff(history.disabled_at) |> abs()
      # NB(@zkat): I think guessing we'll be within 10 seconds of the
      # disable_user call is pretty safe? Adjust this accordingly if it starts
      # failing.
      assert diff < 10

      mod = user_fixture(%{roles: [:mod]})
      user = user_fixture()

      assert {:ok, %DisableHistory{}} =
               Accounts.disable_user(mod, user, %{
                 disabled_reason: "bad actor"
               })

      catch_error(
        Accounts.disable_user(nil, user, %{
          disabled_reason: "bad actor"
        })
      )
    end

    test "fails if the user is already disabled" do
      admin = user_fixture(%{roles: [:admin]})
      user = user_fixture()

      assert {:ok, %DisableHistory{}} =
               Accounts.disable_user(admin, user, %{
                 disabled_reason: "bad actor"
               })

      assert {:error, :already_disabled} =
               Accounts.disable_user(admin, user, %{
                 disabled_reason: "bad actor"
               })
    end

    test "fails if the actor is not an admin or a mod, or is a mod trying to ban an admin" do
      admin = user_fixture(%{roles: [:admin]})
      mod = user_fixture(%{roles: [:mod]})
      user1 = user_fixture()
      user2 = user_fixture()

      assert {:error, :unauthorized} =
               Accounts.disable_user(user1, user2, %{
                 disabled_reason: "bad actor"
               })

      assert {:error, :unauthorized} =
               Accounts.disable_user(mod, admin, %{
                 disabled_reason: "bad actor"
               })
    end

    test "validates disable reason and disabled_until" do
      admin = user_fixture(%{roles: [:admin]})
      user = user_fixture()

      assert {:error, %Ecto.Changeset{} = changeset} =
               Accounts.disable_user(admin, user, %{
                 disabled_reason: gen_random_string(501),
                 disabled_until:
                   NaiveDateTime.utc_now()
                   |> NaiveDateTime.truncate(:second)
                   |> NaiveDateTime.add(-10)
               })

      assert %{
               disabled_reason: ["should be at most 500 character(s)"],
               disabled_until: [
                 "Disabled-until time must be after the time when the user was disabled."
               ]
             } = errors_on(changeset)

      assert {:ok, _} =
               Accounts.disable_user(admin, user, %{
                 disabled_reason: gen_random_string(500),
                 disabled_until:
                   NaiveDateTime.utc_now()
                   |> NaiveDateTime.truncate(:second)
                   |> NaiveDateTime.add(1)
               })
    end

    test "can schedule an automatic unban in the future" do
      admin = user_fixture(%{roles: [:admin]})
      user = user_fixture()

      until =
        NaiveDateTime.utc_now()
        |> NaiveDateTime.add(1000)

      Oban.Testing.with_testing_mode(:manual, fn ->
        assert {:ok, %DisableHistory{}} =
                 Accounts.disable_user(admin, user, %{
                   disabled_reason: "bad actor",
                   disabled_until: until
                 })

        user = Accounts.get_user(user.id) |> Repo.preload(:disable_info)
        assert %DisableHistory{} = user.disable_info

        assert %{success: 1, failure: 0} =
                 Oban.drain_queue(
                   queue: :unban,
                   with_scheduled: DateTime.from_naive!(until, "Etc/UTC")
                 )
      end)

      user = Accounts.get_user(user.id) |> Repo.preload(:disable_info)

      assert is_nil(user.disable_info)
    end

    test "maintains a history of previous bans" do
      %User{id: admin_id} = admin = user_fixture(%{roles: [:admin]})
      user = user_fixture()

      assert {:ok, %DisableHistory{disabled_at: h1_dat}} =
               Accounts.disable_user(admin, user, %{
                 disabled_reason: "bad1"
               })

      assert {:ok, _} = Accounts.enable_user(admin, user, "ok1")

      assert {:ok, %DisableHistory{disabled_at: h2_dat}} =
               Accounts.disable_user(admin, user, %{
                 disabled_reason: "bad2"
               })

      assert {:ok, _} = Accounts.enable_user(admin, user, "ok2")

      assert {:ok, %DisableHistory{disabled_at: h3_dat}} =
               Accounts.disable_user(admin, user, %{
                 disabled_reason: "bad3"
               })

      assert {:ok, _} = Accounts.enable_user(admin, user, "ok3")

      assert {:ok, %DisableHistory{disabled_at: h4_dat}} =
               Accounts.disable_user(admin, user, %{
                 disabled_reason: "bad4"
               })

      assert [
               %DisableHistory{
                 disabled_reason: "bad1",
                 disabled_at: ^h1_dat,
                 disabled_by_id: ^admin_id,
                 lifted_by_id: ^admin_id,
                 lifted_reason: "ok1"
               },
               %DisableHistory{
                 disabled_reason: "bad2",
                 disabled_at: ^h2_dat,
                 disabled_by_id: ^admin_id,
                 lifted_reason: "ok2"
               },
               %DisableHistory{
                 disabled_reason: "bad3",
                 disabled_at: ^h3_dat,
                 disabled_by_id: ^admin_id,
                 lifted_reason: "ok3"
               },
               %DisableHistory{
                 disabled_reason: "bad4",
                 disabled_at: ^h4_dat,
                 disabled_by_id: ^admin_id,
                 lifted_reason: nil
               }
             ] =
               (user |> Repo.preload(:disable_history)).disable_history
               # NB(@zkat): The :preload_order option doesn't seem to work here,
               # probably because these are happening so quickly (and we're truncating
               # to seconds).
               |> Enum.sort_by(& &1.id)
    end
  end

  describe "enable_user/3" do
    test "Re-enables a previously disabled user" do
      %User{id: admin_id} = admin = user_fixture(%{roles: [:admin]})
      user = user_fixture()

      {:ok, %DisableHistory{id: history_id}} =
        Accounts.disable_user(admin, user, %{
          disabled_reason: "bad actor"
        })

      user = user |> Repo.preload(:disable_info)

      assert user.disable_info

      assert {:ok,
              %DisableHistory{
                id: ^history_id,
                lifted_by_id: ^admin_id,
                lifted_reason: "ok actor"
              }} = Accounts.enable_user(admin, user, "ok actor")

      user = user |> Repo.reload(force: true) |> Repo.preload(:disable_info)

      assert is_nil(user.disable_info)
    end

    test "fails if the actor is not an admin or a mod, or is a mod trying to unban an admin" do
      admin = user_fixture(%{roles: [:admin]})
      mod = user_fixture(%{roles: [:mod]})
      user1 = user_fixture()
      user2 = user_fixture()

      {:ok, _} =
        Accounts.disable_user(admin, user2, %{
          disabled_reason: "bad actor"
        })

      {:ok, _} =
        Accounts.disable_user(admin, admin, %{
          disabled_reason: "bad actor"
        })

      assert {:error, :unauthorized} = Accounts.enable_user(user1, user2, "ok now")
      assert {:error, :unauthorized} = Accounts.enable_user(mod, admin, "ok now")
    end

    test "supports passing a `:system` actor to act of behalf of the system." do
      admin = user_fixture(%{roles: [:admin]})
      user = user_fixture()

      {:ok, %DisableHistory{id: history_id}} =
        Accounts.disable_user(admin, user, %{
          disabled_reason: "bad actor"
        })

      assert {:ok, %DisableHistory{id: ^history_id, lifted_by_id: nil, lifted_reason: "ok actor"}} =
               Accounts.enable_user(:system, user, "ok actor")
    end

    test "validates lifted reason" do
      admin = user_fixture(%{roles: [:admin]})
      user = user_fixture()

      {:ok, _} =
        Accounts.disable_user(admin, user, %{
          disabled_reason: "bad actor"
        })

      badreason = gen_random_string(501)
      goodreason = gen_random_string(500)

      assert {:ok, %DisableHistory{lifted_reason: ^goodreason}} =
               Accounts.enable_user(admin, user, goodreason)

      assert {:error, changeset} = Accounts.enable_user(admin, user, badreason)

      assert %{
               lifted_reason: ["should be at most 500 character(s)"]
             } = errors_on(changeset)
    end

    test "cancels existing scheduled unban jobs by default" do
      admin = user_fixture(%{roles: [:admin]})
      user = user_fixture()

      until =
        NaiveDateTime.utc_now()
        |> NaiveDateTime.add(1000)

      Oban.Testing.with_testing_mode(:manual, fn ->
        {:ok, %DisableHistory{lifting_job_id: job_id}} =
          Accounts.disable_user(admin, user, %{
            disabled_reason: "bad actor",
            disabled_until: until
          })

        assert_enqueued(worker: Banchan.Workers.EnableUser, args: %{user_id: user.id})

        assert {:ok, %DisableHistory{lifting_job_id: ^job_id}} =
                 Accounts.enable_user(admin, user, "ok actor")

        refute_enqueued(worker: Banchan.Workers.EnableUser, args: %{user_id: user.id})

        assert %{success: 0, failure: 0} =
                 Oban.drain_queue(
                   queue: :unban,
                   with_scheduled: DateTime.from_naive!(until, "Etc/UTC")
                 )
      end)

      user = Accounts.get_user(user.id) |> Repo.preload(:disable_info)

      assert is_nil(user.disable_info)
    end

    test "does not cancel existing unban jobs if passed `false` as the last argument" do
      admin = user_fixture(%{roles: [:admin]})
      user = user_fixture()

      until =
        NaiveDateTime.utc_now()
        |> NaiveDateTime.add(1000)

      Oban.Testing.with_testing_mode(:manual, fn ->
        {:ok, %DisableHistory{lifting_job_id: job_id}} =
          Accounts.disable_user(admin, user, %{
            disabled_reason: "bad actor",
            disabled_until: until
          })

        assert_enqueued(worker: Banchan.Workers.EnableUser, args: %{user_id: user.id})

        assert {:ok, %DisableHistory{lifting_job_id: ^job_id}} =
                 Accounts.enable_user(admin, user, "ok actor", false)

        assert_enqueued(worker: Banchan.Workers.EnableUser, args: %{user_id: user.id})
      end)

      user = Accounts.get_user(user.id) |> Repo.preload(:disable_info)

      assert is_nil(user.disable_info)
    end
  end
end
