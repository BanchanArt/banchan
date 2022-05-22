defmodule BanchanWeb.ProfileImageController do
  @moduledoc """
  "securely" serves profile-related pictures
  """
  use BanchanWeb, :controller

  alias Banchan.Uploads

  def profile_image(conn, %{"id" => upload_id}) do
    upload = Uploads.get_by_id!(upload_id)

    conn
    |> put_resp_header("content-length", "#{upload.size}")
    |> put_resp_header(
      "content-disposition",
      "attachment; filename=\"#{upload.name || upload.key}\""
    )
    |> put_resp_header("cache-control", "max-age=604800, must-revalidate")
    |> put_resp_content_type(upload.type)
    |> send_chunked(200)
    |> then(
      &Enum.reduce_while(Uploads.stream_data!(upload), &1, fn chunk, conn ->
        case chunk(conn, chunk) do
          {:ok, conn} ->
            {:cont, conn}

          {:error, :closed} ->
            {:halt, conn}
        end
      end)
    )
  end
end
