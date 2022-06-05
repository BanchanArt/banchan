defmodule Banchan.UploadsTest do
  use Banchan.DataCase, async: true

  alias Banchan.Uploads

  describe "uploads" do
    alias Banchan.Uploads.Upload

    @valid_attrs %{bucket: "bucket", key: "uuid_goes_here", type: "image/png", size: 10_000}
    @invalid_attrs %{status: nil, title: nil, type: nil, size: nil}

    def upload_fixture(attrs \\ %{}) do
      {:ok, upload} = Uploads.create_upload(attrs |> Enum.into(@valid_attrs))
      upload
    end

    @tag :skip
    test "delete_upload/2 deletes the upload with the given id" do
      upload = upload_fixture()
      id = upload.id
      {:ok, %Upload{id: ^id}} = Uploads.delete_upload(upload, false)
      assert_raise Ecto.NoResultsError, fn -> Uploads.get_upload!(upload.id) end
    end
  end
end
