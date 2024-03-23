defmodule Banchan.WorksFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Banchan.Works` context.
  """

  import Banchan.AccountsFixtures
  import Banchan.StudiosFixtures

  alias Banchan.Uploads

  @doc """
  Generate a work.
  """
  def work_fixture(attrs \\ %{}) do
    artist = Map.get(attrs, :artist, user_fixture(%{roles: [:artist]}))
    studio = Map.get(attrs, :studio, studio_fixture([artist]))

    uploads =
      Map.get(attrs, :uploads, [
        %{name: "test.png", dir: "file-types/image", type: "image/png"},
        %{name: "test.jpg", dir: "file-types/image", type: "image/jpg"},
        %{name: "sample_640x360.webm", dir: "file-types/video", type: "video/webm"}
      ])

    uploads =
      uploads
      |> Enum.map(fn file ->
        Uploads.save_file!(
          artist,
          Path.expand(Path.join(["..", file.dir, file.name]), __DIR__),
          file.type,
          file.name
        )
      end)

    {:ok, work} =
      Banchan.Works.new_work(
        artist,
        studio,
        attrs
        |> Enum.into(%{
          private: false,
          description: "some description",
          title: "some title",
          tags: ["option1", "option2"],
          mature: false
        })
        |> Map.new(fn {k, v} -> {to_string(k), v} end),
        uploads,
        commission: Map.get(attrs, :commission),
        offering: Map.get(attrs, :offering)
      )

    work
  end
end
