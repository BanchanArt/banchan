defmodule BanchanWeb.ReportBugLive.New do
  @moduledoc """
  Lets users submit GitHub bugs without having GitHub accounts themselves.
  """
  use BanchanWeb, :live_view

  alias Banchan.Reports

  alias Surface.Components.Form

  alias BanchanWeb.Components.{Button, Layout}
  alias BanchanWeb.Components.Form.{Checkbox, QuillInput, Submit, TextInput}

  @impl true
  def handle_params(_params, _uri, socket) do
    {:noreply, assign(socket, report_url: nil)}
  end

  @impl true
  def handle_event(
        "submit",
        %{"bug_report" => %{"title" => title, "body" => body, "bug?" => bug?}},
        socket
      ) do
    case Reports.report_bug(
           socket.assigns.current_user,
           title,
           body,
           bug?,
           &~p"/people/#{&1.handle}"
         ) do
      {:ok, url} ->
        {:noreply, socket |> assign(report_url: url)}

      {:error, :internal_error} ->
        {:noreply,
         socket
         |> put_flash(
           :error,
           "An internal error occurred while trying to file this bug report. Try again later, or email us at support@banchan.art."
         )}
    end
  end

  def handle_event("reset", _, socket) do
    {:noreply, socket |> assign(report_url: nil)}
  end

  @impl true
  def render(assigns) do
    ~F"""
    <Layout flashes={@flash} padding={0}>
      <div class="w-full bg-base-200">
        <div class="w-full max-w-lg p-4 mx-auto rounded-xl md:my-10 bg-base-200">
          {#if @report_url}
            <p>Thanks for your feedback! You can view the issue and sign up for updates <a href={@report_url} class="link link-primary">here</a>.</p>
            <Button label="Report Another" click="reset" />
          {#else}
            <Form class="flex flex-col gap-4" for={%{}} as={:bug_report} submit="submit">
              <h1 class="text-2xl">Submit feedback</h1>
              <p>To submit feedback for Banchan Art, you may use this form or <a href="https://github.com/BanchanArt/banchan/issues/new/choose" class="link">Github</a>. Please include as much context as you can.</p>
              <p>You may view existing issues using our <a href="https://github.com/BanchanArt/banchan/issues" class="link">Github issues page.</a></p>
              <p><span class="text-error">NOTE: This feedback will be <span class="font-bold">publicly visible</span> on GitHub. Do NOT include any personal or confidential information.</span></p>
              <p>If you need support for something that shouldn't be public, please contact us at <a href="mailto:support@banchan.art" class="link">support@banchan.art</a>.</p>
              <TextInput name={:title} label="Title" opts={required: true, maxlength: "256", minlength: "10"} />
              <QuillInput
                id="body-input"
                name={:body}
                label="Body"
                opts={required: true, maxlength: "2000", minlength: "30"}
              />
              <Checkbox name={:bug?} label="Bug Report" opts={"aria-label": "Bug Report"} />
              <Submit />
            </Form>
          {/if}
        </div>
      </div>
    </Layout>
    """
  end
end
