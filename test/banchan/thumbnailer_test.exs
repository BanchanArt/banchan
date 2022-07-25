defmodule Banchan.Workers.ThumbnailerTest do
  use BanchanWeb.ConnCase

  import Banchan.AccountsFixtures

  require Logger

  alias Banchan.Uploads
  alias Banchan.Workers.Thumbnailer

  @upload_dir Application.compile_env!(:banchan, :upload_dir)

  describe "thumbnailer" do
    test "supported image file types" do
      user = user_fixture()

      files = [
        %{name: "test.bmp", type: "image/bmp"},
        %{name: "test.gif", type: "image/gif"},
        %{name: "test.ico", type: "image/vnd.microsoft.icon"},
        %{name: "test.jpg", type: "image/jpg"},
        %{name: "test.png", type: "image/png"},
        %{name: "sample_640426.psd", type: "image/vnd.adobe.photoshop"},
        %{name: "test.svg", type: "image/svg+xml"},
        %{name: "test.svgz", type: "image/svg+xml"},
        %{name: "test.tiff", type: "image/tiff"},
        %{name: "test.webp", type: "image/webp"}
      ]

      Enum.map(files, fn file ->
        upload =
          Uploads.save_file!(
            user,
            Path.expand("../../test/support/file-types/image/" <> file.name, __DIR__),
            file.type,
            file.name
          )

        assert {:ok, _} = Thumbnailer.thumbnail(upload)
      end)
    end

    test "resize image upload to match opts" do
      user = user_fixture()
      image_src = Path.expand("../support/file-types/image/test.png", __DIR__)
      image_type = "image/png"
      image_name = "test.png"

      upload = Uploads.save_file!(user, image_src, image_type, image_name)

      assert {:ok, thumbnail} =
               Thumbnailer.thumbnail(
                 upload,
                 dimensions: "128x128"
               )

      assert %{width: 128, height: 128} =
               Path.join([@upload_dir, thumbnail.bucket <> "/" <> thumbnail.key])
               |> Mogrify.open()
               |> Mogrify.verbose()
    end
  end

  test "unsupported file type" do
    user = user_fixture()
    image_src = Path.expand("../support/file-types/image/test.eps", __DIR__)
    image_type = "application/postscript"
    image_name = "test.eps"

    upload = Uploads.save_file!(user, image_src, image_type, image_name)

    assert {:error, :unsupported_input} = Thumbnailer.thumbnail(upload)
  end
end
