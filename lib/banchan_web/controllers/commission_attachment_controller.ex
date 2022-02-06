defmodule BanchanWeb.CommissionAttachmentController do
  @moduledoc """
  "securely" serves attachment data from commissions.
  """
  use BanchanWeb, :controller

  alias Banchan.Commissions
  alias Banchan.Uploads

  def show(conn, %{"handle" => studio_handle, "commission_id" => public_id, "key" => key}) do
    attachment =
      Commissions.get_attachment_if_allowed!(studio_handle, public_id, key, conn.assigns.current_user)

    conn
    |> put_resp_header("content-length", "#{attachment.upload.size}")
    |> put_resp_header("content-disposition", "attachment; filename=\"#{attachment.upload.name || attachment.upload.key}\"")
    |> put_resp_content_type(attachment.upload.type)
    |> send_chunked(200)
    |> then(&Enum.reduce_while(Uploads.stream_data!(attachment.upload), &1, fn chunk, conn ->
      case chunk(conn, chunk) do
        {:ok, conn} ->
          {:cont, conn}

        {:error, :closed} ->
          {:halt, conn}
      end
    end))
  end
end
