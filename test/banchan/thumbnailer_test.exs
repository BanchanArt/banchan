defmodule Banchan.Workers.ThumbnailerTest do
  use BanchanWeb.ConnCase

  import Banchan.AccountsFixtures

  require Logger

  alias Banchan.Workers.Thumbnailer
  alias Banchan.Uploads

  @upload_dir Path.expand("../../priv/uploads", __DIR__)

  describe "thumbnailer" do
    test "resize image upload to match opts" do
      user = user_fixture()
      image_src = "test/support/file-types/image/test.png"
      image_type = "image/png"
      image_name = "test.png"

      upload = Uploads.save_file!(user, image_src, image_type, image_name)

      assert {:ok, thumbnail} =
               Thumbnailer.thumbnail(
                 upload,
                 dimensions: "128x128"
               )

      assert %{width: 128, height: 128} =
               Path.join(@upload_dir, thumbnail.bucket <> "/" <> thumbnail.key)
               |> Mogrify.open()
               |> Mogrify.verbose()
    end
  end
end
