defmodule BanchanWeb.WorkUploadsController do
  @moduledoc """
  Serves work uploads and previews, taking into account permissions.
  """
  use BanchanWeb, :controller

  alias Banchan.Studios
  alias Banchan.Uploads
  alias Banchan.Works

  def show(conn, %{"handle" => studio_handle, "work_id" => public_id, "upload_id" => upload_id}) do
    studio = Studios.get_studio_by_handle!(studio_handle)
    work = Works.get_work_by_public_id_if_allowed!(studio, public_id, conn.assigns.current_user)

    if Works.can_download_uploads?(conn.assigns.current_user, work) do
      work_upload = Works.get_work_upload_if_allowed!(work, upload_id, conn.assigns.current_user)

      conn
      |> put_resp_header("content-length", "#{work_upload.upload.size}")
      |> put_resp_header(
        "content-disposition",
        "attachment; filename=\"#{work_upload.upload.name || work_upload.upload.key}\""
      )
      |> put_resp_content_type(work_upload.upload.type)
      |> send_chunked(200)
      |> then(
        &Enum.reduce_while(Uploads.stream_data!(work_upload.upload), &1, fn chunk, conn ->
          case chunk(conn, chunk) do
            {:ok, conn} ->
              {:cont, conn}

            {:error, :closed} ->
              {:halt, conn}
          end
        end)
      )
    else
      conn
      |> resp(404, "Not Found")
      |> send_resp()
    end
  end

  def preview(conn, %{"handle" => studio_handle, "work_id" => public_id, "upload_id" => upload_id}) do
    studio = Studios.get_studio_by_handle!(studio_handle)
    work = Works.get_work_by_public_id_if_allowed!(studio, public_id, conn.assigns.current_user)
    work_upload = Works.get_work_upload_if_allowed!(work, upload_id, conn.assigns.current_user)

    if work_upload.preview && !work_upload.preview.pending do
      conn
      |> put_resp_header("content-length", "#{work_upload.preview.size}")
      |> put_resp_content_type(work_upload.preview.type)
      |> send_resp(200, Uploads.get_data!(work_upload.preview))
    else
      conn
      |> resp(404, "Not Found")
      |> send_resp()
    end
  end
end
