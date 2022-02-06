defmodule BanchanWeb.ProfileImageController do
  @moduledoc """
  "securely" serves profile-related pictures
  """
  use BanchanWeb, :controller

  alias Banchan.Accounts
  alias Banchan.Uploads
  alias Banchan.Uploads.Upload

  def pfp(conn, %{"handle" => handle}) do
    user = Accounts.get_user_by_handle!(handle)

    conn
    |> do_upload(user.pfp_img)
  end

  def thumb(conn, %{"handle" => handle}) do
    user = Accounts.get_user_by_handle!(handle)

    conn
    |> do_upload(user.pfp_thumb)
  end

  def header(conn, %{"handle" => handle}) do
    user = Accounts.get_user_by_handle!(handle)

    conn
    |> do_upload(user.header_img)
  end

  defp do_upload(conn, %Upload{} = upload) do
    # TODO: upload a "default" image if upload is nil?
    conn
    |> put_resp_header("content-length", "#{upload.size}")
    |> put_resp_header(
      "content-disposition",
      "attachment; filename=\"#{upload.name || upload.key}\""
    )
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
