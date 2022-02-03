defmodule BanchanWeb.StudioLive.Components.Commissions.CommentBox do
  @moduledoc """
  Message/Chat box for the Commission page.
  """
  use BanchanWeb, :live_component

  alias Banchan.Commissions
  alias Banchan.Commissions.Event

  alias Surface.Components.Form

  alias BanchanWeb.Components.Form.{Submit, MarkdownInput}

  prop commission, :struct, required: true
  prop actor, :struct, required: true

  data changeset, :struct

  def mount(socket) do
    {:ok,
     assign(socket,
       changeset:
         Commissions.change_event(
           %Event{
             type: :comment
           },
           %{}
         )
     )}
  end

  def handle_event("change", %{"event" => event}, socket) do
    changeset =
      %Event{
        type: :comment,
        actor: socket.assigns.actor,
        commission: socket.assigns.commission
      }
      |> Commissions.change_event(event)
      |> Map.put(:action, :update)

    {:noreply, assign(socket, changeset: changeset)}
  end

  def handle_event("add_comment", %{"event" => event}, socket) do
    case Commissions.create_event(
           :comment,
           socket.assigns.actor,
           socket.assigns.commission,
           event
         ) do
      {:ok, event} ->
        BanchanWeb.Endpoint.broadcast!(
          "commission:#{socket.assigns.commission.public_id}",
          "new_comment",
          event
        )

        {:noreply,
         assign(socket,
           changeset:
             Commissions.change_event(
               %Event{
                 type: :comment
               },
               %{}
             )
         )}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  def render(assigns) do
    ~F"""
    <div class="message-box">
      <Form for={@changeset} change="change" submit="add_comment">
        <div class="block space-y-4">
          <MarkdownInput
            id="initial-message"
            name={:text}
            show_label={false}
            class="w-full"
            opts={required: true, placeholder: "Here's what I'd like..."}
          />
          <Submit changeset={@changeset} label="Reply" />
        </div>
      </Form>
    </div>
    """
  end
end
