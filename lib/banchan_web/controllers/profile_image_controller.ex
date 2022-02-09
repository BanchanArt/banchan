defmodule BanchanWeb.ProfileImageController do
  @moduledoc """
  "securely" serves profile-related pictures
  """
  use BanchanWeb, :controller

  alias Banchan.Accounts
  alias Banchan.Uploads
  alias Banchan.Uploads.Upload

  alias BanchanWeb.Endpoint

  def pfp(conn, %{"handle" => handle}) do
    user = Accounts.get_user_by_handle!(handle)

    conn
    |> do_upload(user.pfp_img, :pfp_img)
  end

  def thumb(conn, %{"handle" => handle}) do
    user = Accounts.get_user_by_handle!(handle)

    conn
    |> do_upload(user.pfp_thumb, :pfp_thumb)
  end

  def header(conn, %{"handle" => handle}) do
    user = Accounts.get_user_by_handle!(handle)

    conn
    |> do_upload(user.header_img, :header_img)
  end

  defp do_upload(conn, %Upload{} = upload, _) do
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

  defp do_upload(conn, _, :pfp_img) do
    conn
    |> redirect(to: Routes.static_path(Endpoint, "/images/denizen_default_icon.png"))
  end

  defp do_upload(conn, _, :pfp_thumb) do
    conn
    |> redirect(to: Routes.static_path(Endpoint, "/images/denizen_default_icon.png"))
  end

  defp do_upload(conn, _, :header_img) do
    conn
    |> resp(404, "")
    |> send_resp()
  end
end
