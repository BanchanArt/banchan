defmodule BanchanWeb.PublicImageController do
  @moduledoc """
  Serves public image uploads.
  """
  use BanchanWeb, :controller

  alias Banchan.Accounts
  alias Banchan.Offerings
  alias Banchan.Studios
  alias Banchan.Uploads

  def download(conn, %{"id" => upload_id, "type" => type}) do
    upload = get_by_type!(type, upload_id)

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

  def image(conn, %{"id" => upload_id, "type" => type}) do
    upload = get_by_type!(type, upload_id)

    conn
    |> put_resp_header("content-length", "#{upload.size}")
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

  defp get_by_type!(type, upload_id)

  defp get_by_type!("offering_card_img", id) do
    Offerings.offering_card_img!(id)
  end

  defp get_by_type!("offering_header_img", id) do
    Offerings.offering_header_img!(id)
  end

  defp get_by_type!("offering_gallery_img", id) do
    Offerings.offering_gallery_img!(id)
  end

  defp get_by_type!("studio_card_img", id) do
    Studios.studio_card_img!(id)
  end

  defp get_by_type!("studio_header_img", id) do
    Studios.studio_header_img!(id)
  end

  defp get_by_type!("studio_portfolio_img", id) do
    Studios.studio_portfolio_img!(id)
  end

  defp get_by_type!("user_header_img", id) do
    Accounts.user_header_img!(id)
  end

  defp get_by_type!("user_pfp_img", id) do
    Accounts.user_pfp_img!(id)
  end

  defp get_by_type!("user_pfp_thumb", id) do
    Accounts.user_pfp_thumb!(id)
  end
end
