defmodule Banchan.WorksTest do
  use Banchan.DataCase

  import Banchan.AccountsFixtures
  import Banchan.CommissionsFixtures
  import Banchan.OfferingsFixtures
  import Banchan.StudiosFixtures
  import Banchan.WorksFixtures

  alias Ecto.Adapters.SQL.Sandbox

  alias Banchan.Studios
  alias Banchan.Uploads
  alias Banchan.Works
  alias Banchan.Works.Work

  @invalid_attrs %{private: nil, description: nil, title: nil, tags: nil, mature: nil}

  setup do
    # Explicitly get a connection before each test
    :ok = Sandbox.checkout(Repo)
    # Setting the mode must be done only after checkout
    Sandbox.mode(Banchan.Repo, :auto)

    on_exit(fn -> Sandbox.mode(Banchan.Repo, :manual) end)
  end

  describe "list_works/1" do
    test "returns all works" do
      work = work_fixture()

      assert Works.list_works(page_size: 200).entries
             |> Enum.map(&Repo.preload(&1, :uploads))
             |> Enum.find(&(&1 == work))
    end

    test "supports free text query" do
      work1 = work_fixture(%{description: "foo"})
      work2 = work_fixture(%{title: "foo"})
      work3 = work_fixture(%{tags: ["foo"]})
      work4 = work_fixture(%{title: "bar", description: "bar"})

      listing = Works.list_works(query: "foo", page_size: 200).entries

      assert Enum.find(listing, &(&1.id == work1.id))
      assert Enum.find(listing, &(&1.id == work2.id))
      assert Enum.find(listing, &(&1.id == work3.id))
      assert Enum.find(listing, &(&1.id == work4.id)) == nil
    end

    test "supports filtering by studio" do
      artist = user_fixture(%{roles: [:artist]})
      studio = studio_fixture([artist])

      work1 = work_fixture(%{artist: artist, studio: studio})
      work2 = work_fixture()

      listing = Works.list_works(studio: studio, page_size: 200).entries

      assert Enum.find(listing, &(&1.id == work1.id))
      assert Enum.find(listing, &(&1.id == work2.id)) == nil
    end

    test "supports filtering by client" do
      client = user_fixture()

      work1 = work_fixture(%{client: client})
      work2 = work_fixture()

      listing = Works.list_works(client: client, page_size: 200).entries

      assert Enum.find(listing, &(&1.id == work1.id))
      assert Enum.find(listing, &(&1.id == work2.id)) == nil
    end

    test "supports filtering by offering" do
      artist = user_fixture(%{roles: [:artist]})
      studio = studio_fixture([artist])
      offering = offering_fixture(studio)

      work1 = work_fixture(%{artist: artist, studio: studio, offering: offering})
      work2 = work_fixture()

      listing = Works.list_works(offering: offering, page_size: 200).entries

      assert Enum.find(listing, &(&1.id == work1.id))
      assert Enum.find(listing, &(&1.id == work2.id)) == nil
    end

    test "supports filtering by commission" do
      artist = user_fixture(%{roles: [:artist]})
      studio = studio_fixture([artist])
      offering = offering_fixture(studio)

      commission =
        commission_fixture(%{
          artist: artist,
          studio: studio,
          offering: offering
        })

      work1 = work_fixture(%{artist: artist, studio: studio, commission: commission})
      work2 = work_fixture()

      listing = Works.list_works(commission: commission, page_size: 200).entries

      assert Enum.find(listing, &(&1.id == work1.id))
      assert Enum.find(listing, &(&1.id == work2.id)) == nil
    end

    test "filters out works if studio has current user blocked" do
      blocked_user = user_fixture()
      artist = user_fixture(%{roles: [:artist]})
      studio = studio_fixture([artist])

      Studios.block_user(artist, studio, blocked_user)

      blocked_work = work_fixture(%{artist: artist, studio: studio})

      listing = Works.list_works(current_user: blocked_user, page_size: 200).entries

      assert Enum.find(listing, &(&1.id == blocked_work.id)) == nil
    end

    test "filters out works based on mature setting" do
      user = user_fixture(%{mature_ok: false})
      mature_user = user_fixture(%{mature_ok: true})
      work = work_fixture(%{mature: true})

      no_user_listing = Works.list_works(page_size: 200).entries
      assert Enum.find(no_user_listing, &(&1.id == work.id)) == nil

      with_user = Works.list_works(current_user: user, page_size: 200).entries
      assert Enum.find(with_user, &(&1.id == work.id)) == nil

      with_mature_user = Works.list_works(current_user: mature_user, page_size: 200).entries
      assert Enum.find(with_mature_user, &(&1.id == work.id))
    end

    test "filters out works based on current user's mutes" do
      user = user_fixture()
      muted_user = user_fixture(%{muted: "foo bar baz"})

      work1 = work_fixture(%{title: "foo"})
      work2 = work_fixture(%{description: "bar"})
      work3 = work_fixture(%{tags: ["baz"]})

      no_user_listing = Works.list_works(page_size: 200).entries
      assert Enum.find(no_user_listing, &(&1.id == work1.id))
      assert Enum.find(no_user_listing, &(&1.id == work2.id))
      assert Enum.find(no_user_listing, &(&1.id == work3.id))

      user_listing = Works.list_works(current_user: user, page_size: 200).entries
      assert Enum.find(user_listing, &(&1.id == work1.id))
      assert Enum.find(user_listing, &(&1.id == work2.id))
      assert Enum.find(user_listing, &(&1.id == work3.id))

      muted_user_listing = Works.list_works(current_user: muted_user, page_size: 200).entries
      assert Enum.find(muted_user_listing, &(&1.id == work1.id)) == nil
      assert Enum.find(muted_user_listing, &(&1.id == work2.id)) == nil
      assert Enum.find(muted_user_listing, &(&1.id == work3.id)) == nil
    end

    test "does not list private works unless there's a current user who's either an artist for the studio, or the client" do
      user = user_fixture()
      client = user_fixture()
      artist = user_fixture()
      studio = studio_fixture([artist])

      private_work =
        work_fixture(%{
          artist: artist,
          studio: studio,
          client: client,
          private: true
        })

      no_user_listing = Works.list_works(page_size: 200).entries
      assert Enum.find(no_user_listing, &(&1.id == private_work.id)) == nil

      user_listing = Works.list_works(current_user: user, page_size: 200).entries
      assert Enum.find(user_listing, &(&1.id == private_work.id)) == nil

      client_listing = Works.list_works(current_user: client, page_size: 200).entries
      assert Enum.find(client_listing, &(&1.id == private_work.id))

      artist_listing = Works.list_works(current_user: artist, page_size: 200).entries
      assert Enum.find(artist_listing, &(&1.id == private_work.id))
    end

    test "supports listing related Works" do
      unrelated_work = work_fixture()
      work1 = work_fixture(%{title: "foo", description: "bar", tags: ["bar", "baz"]})
      work2 = work_fixture(%{title: "foo"})
      work3 = work_fixture(%{description: "bar"})
      work4 = work_fixture(%{tags: ["bar"]})
      work5 = work_fixture(%{tags: ["baz"]})
      work6 = work_fixture(%{title: "bar", description: "foo"})

      listing = Works.list_works(related_to: work1, page_size: 200).entries

      assert Enum.find(listing, &(&1.id == unrelated_work.id)) == nil
      assert Enum.find(listing, &(&1.id == work1.id)) == nil
      assert Enum.find(listing, &(&1.id == work2.id))
      assert Enum.find(listing, &(&1.id == work3.id))
      assert Enum.find(listing, &(&1.id == work4.id))
      assert Enum.find(listing, &(&1.id == work5.id))
      assert Enum.find(listing, &(&1.id == work6.id))
    end
  end

  describe "get_work!/1" do
    @invalid_attrs %{private: nil, description: nil, title: nil, tags: nil, mature: nil}
    test "returns the work with given id" do
      work = work_fixture()
      assert Works.get_work!(work.id) == (work |> Repo.preload([uploads: [:upload]]))
    end
  end

  describe "new_work/1" do
    test "valid data creates a work" do
      client = user_fixture()
      comm = commission_fixture(%{client: client})
      studio = comm.studio
      artist = Enum.at(studio.artists, 0)

      uploads = [
        Uploads.save_file!(
          client,
          Path.expand("../support/file-types/image/test.png", __DIR__),
          "image/png",
          "test.png"
        )
      ]

      valid_attrs = %{
        private: true,
        description: "some description",
        title: "some title",
        tags: ["option1", "option2"],
        mature: true
      }

      assert {:ok, %Work{} = work} =
               Works.new_work(artist, studio, valid_attrs, uploads, commission: comm)

      assert work.private == true
      assert work.description == "some description"
      assert work.title == "some title"
      assert work.tags == ["option1", "option2"]
      assert work.mature == true

      work = work |> Repo.preload([:client, :studio, :commission])

      assert work.client.id == client.id
      assert work.studio.id == studio.id
      assert work.commission.id == comm.id
    end

    test "invalid data returns error changeset" do
      artist = user_fixture()
      studio = studio_fixture([artist])

      uploads = [
        Uploads.save_file!(
          artist,
          Path.expand("../support/file-types/image/test.png", __DIR__),
          "image/png",
          "test.png"
        )
      ]

      assert {:error, %Ecto.Changeset{}} = Works.new_work(artist, studio, @invalid_attrs, uploads)
    end

    test "requires non-empty uploads" do
      artist = user_fixture()
      studio = studio_fixture([artist])
      uploads = []
      assert {:error, :uploads_required} = Works.new_work(artist, studio, @invalid_attrs, uploads)
    end
  end

  @tag skip: "TODO"
  describe "update_work/4" do
    test "valid data updates the work" do
      work = work_fixture()

      update_attrs = %{
        private: false,
        description: "some updated description",
        title: "some updated title",
        tags: ["option1"],
        mature: false
      }

      assert {:ok, %Work{} = work} = Works.update_work(work, update_attrs)
      assert work.private == false
      assert work.description == "some updated description"
      assert work.title == "some updated title"
      assert work.tags == ["option1"]
      assert work.mature == false
    end
  end
end
