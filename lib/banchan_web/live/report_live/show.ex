defmodule BanchanWeb.ReportLive.Show do
  @moduledoc """
  Shows report details and allows editing.
  """
  use BanchanWeb, :live_view

  alias Banchan.Reports
  alias Banchan.Reports.Report

  alias Surface.Components.{Form, LiveRedirect}

  alias BanchanWeb.Components.{Avatar, Button, Icon, Layout, Markdown, UserHandle}
  alias BanchanWeb.Components.Form.{QuillInput, Select, Submit}

  @impl true
  def handle_params(%{"id" => report_id}, _uri, socket) do
    report = Reports.get_report_by_id!(report_id)

    {:noreply,
     socket
     |> assign(
       report: report,
       changeset: Report.update_changeset(report, %{})
     )}
  end

  @impl true
  def handle_event("change", %{"report" => report}, socket) do
    changeset =
      socket.assigns.report
      |> Report.update_changeset(report)
      |> Map.put(:action, :update)

    {:noreply, socket |> assign(changeset: changeset)}
  end

  @impl true
  def handle_event("submit", %{"report" => report}, socket) do
    case Reports.update_report(socket.assigns.current_user, socket.assigns.report, report) do
      {:ok, report} ->
        {:noreply,
         socket
         |> assign(
           report: report,
           changeset: Report.update_changeset(report, %{})
         )}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, socket |> assign(changeset: changeset)}
    end
  end

  @impl true
  def handle_event("self_assign", _, socket) do
    case Reports.assign_report(
           socket.assigns.current_user,
           socket.assigns.report,
           socket.assigns.current_user
         ) do
      {:ok, report} ->
        {:noreply,
         socket
         |> assign(
           report: report,
           changeset: Report.update_changeset(report, %{})
         )}

      {:error, :not_an_admin} ->
        {:noreply,
         socket
         |> put_flash(:error, "You are not authorized to perform this action.")
         |> push_navigate(to: Routes.home_path(Endpoint, :index))}

      {:error, :unauthorized} ->
        {:noreply,
         socket
         |> put_flash(:error, "You are not authorized to perform this action.")
         |> push_navigate(to: Routes.home_path(Endpoint, :index))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, socket |> assign(changeset: changeset)}
    end
  end

  @impl true
  def handle_event("unassign", _, socket) do
    case Reports.assign_report(socket.assigns.current_user, socket.assigns.report, nil) do
      {:ok, report} ->
        {:noreply,
         socket
         |> assign(
           report: report,
           changeset: Report.update_changeset(report, %{})
         )}

      {:error, :unauthorized} ->
        {:noreply,
         socket
         |> put_flash(:error, "You are not authorized to perform this action.")
         |> push_navigate(to: Routes.home_path(Endpoint, :index))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, socket |> assign(changeset: changeset)}
    end
  end

  @impl true
  def render(assigns) do
    ~F"""
    <Layout flashes={@flash} context={:admin}>
      <div class="relative">
        <h1 class="sticky z-10 flex flex-row items-center px-4 pb-2 text-3xl border-b-2 opacity-100 top-16 bg-base-100 border-base-content border-opacity-10">
          <LiveRedirect class="px-2 pb-4" to={Routes.report_index_path(Endpoint, :index)}>
            <Icon name="arrow-left" size="4" />
          </LiveRedirect>
          <div class="flex flex-row items-center w-full gap-2 px-2 pb-2">
            Viewing Report
            <div class="badge badge-primary badge-xl">{@report.status}</div>
          </div>
        </h1>
        <div class="w-full">
          <div class="flex flex-col w-full h-full max-w-xl mx-auto md:my-4 bg-base-100">
            <div class="flex flex-row text-xl">
              Reported by
              <Avatar class="w-8 mx-2" user={@current_user} />
              <UserHandle user={@current_user} />
              <div class="mx-2">
                {Timex.format!(@report.inserted_at, "{relative}", :relative)}
              </div>
            </div>
            <div class="flex flex-col gap-2 md:flex-row">
              <span class="text-xl font-semibold">URL:</span>
              <LiveRedirect to={@report.uri}>
                <span class="link">
                  {@report.uri}
                </span>
              </LiveRedirect>
            </div>
            <div class="flex flex-row flex-wrap items-center gap-2 text-xl">
              <div class="flex flex-row items-center gap-2 grow">
                Assigned to
                {#if @report.investigator}
                  <Avatar class="w-8 mx-2" user={@current_user} />
                  <UserHandle user={@current_user} />
                {#else}
                  <span class="font-semibold">Nobody</span>
                {/if}
              </div>
              {#if is_nil(@report.investigator) || @report.investigator.id != @current_user.id}
                <Button class="btn-link" click="self_assign">
                  Assign to Myself
                </Button>
              {/if}
              {#if @report.investigator}
                <Button class="btn-link" click="unassign">
                  Unassign
                </Button>
              {/if}
            </div>
            <div class="divider" />
            <h2 class="text-xl font-semibold">
              Report
            </h2>
            <Markdown content={@report.message} class="pt-4" />
            <div class="divider" />
            <Form for={@changeset} change="change" submit="submit">
              <Select
                name={:status}
                options={
                  New: :new,
                  Investigating: :investigating,
                  Resolved: :resolved
                }
              />
              <QuillInput id="notes-field" name={:notes} />
              <Submit changeset={@changeset} />
            </Form>
          </div>
        </div>
      </div>
    </Layout>
    """
  end
end
