defmodule BanchanWeb.Components.ReportModal do
  @moduledoc """
  Generic modal for submitting content reports.
  """
  use BanchanWeb, :live_component

  alias Banchan.Reports
  alias Banchan.Reports.Report

  alias Surface.Components.Form

  alias BanchanWeb.Components.Form.{QuillInput, Submit}
  alias BanchanWeb.Components.Modal

  prop current_user, :struct, required: true

  data report_uri, :string, default: nil
  data report, :struct

  def update(assigns, socket) do
    socket = socket |> assign(assigns)

    socket =
      socket
      |> assign(report: %Report{} |> Report.creation_changeset(%{uri: socket.assigns.report_uri}))

    {:ok, socket}
  end

  def show(id, uri) do
    send_update(__MODULE__, id: id, report_uri: uri)
    Modal.show(id <> "-inner-modal")
  end

  def handle_event("change", %{"report" => report}, socket) do
    changeset =
      %Report{}
      |> Report.creation_changeset(
        Enum.into(report, %{
          "uri" => socket.assigns.report_uri
        })
      )
      |> Map.put(:action, :update)

    {:noreply, socket |> assign(report: changeset)}
  end

  def handle_event("submit", %{"report" => report}, socket) do
    case Reports.new_report(
           socket.assigns.current_user,
           Enum.into(report, %{
             "uri" => socket.assigns.report_uri
           })
         ) do
      {:ok, _} ->
        Modal.hide(socket.assigns.id <> "-inner-modal")

        {:noreply,
         socket
         |> put_flash(
           :info,
           "Thank you for your report. Admins will review it and take action as necessary."
         )
         |> redirect(external: socket.assigns.report_uri)}

      {:error, %Ecto.Changeset{} = report} ->
        {:noreply, socket |> assign(report: report)}
    end
  end

  def render(assigns) do
    ~F"""
    <div>
      <Modal id={@id <> "-inner-modal"}>
        <:title>Report Abuse</:title>
        <Form for={@report} change="change" submit="submit">
          <QuillInput id={@id <> "-markdown-input"} name={:message} show_label={false} />
          <Submit changeset={@report} label="Report" />
        </Form>
      </Modal>
    </div>
    """
  end
end
