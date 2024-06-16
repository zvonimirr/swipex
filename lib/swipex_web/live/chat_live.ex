defmodule SwipexWeb.ChatLive do
  use SwipexWeb, :live_view
  alias Phoenix.PubSub

  def mount(%{"id" => id}, %{"user_id" => user_id}, socket) do
    IO.inspect({id, user_id})

    with true <- Swipex.User.has_matched(id, user_id),
         {:ok, user} <- Swipex.User.get_user_by_id(id) do
      PubSub.subscribe(Swipex.PubSub, "swipex")
      {:ok, assign(socket, :recipient, user)}
    else
      _ ->
        {:ok, socket |> put_flash(:error, "Something went wrong.") |> redirect(to: "/profile")}
    end
  end

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> put_flash(:error, "You must be logged in to access this page.")
     |> redirect(to: "/login")}
  end

  def handle_event("send", %{"content" => content}, socket) do
    case Swipex.Chat.send_message(
           socket.assigns.user["id"],
           socket.assigns.recipient["id"],
           content
         ) do
      {:ok, _} ->
        PubSub.broadcast(Swipex.PubSub, "swipex", {:message, socket.assigns.recipient["id"]})
        {:noreply, socket |> put_flash(:info, "Message sent.")}

      {:error, _} ->
        {:noreply, socket |> put_flash(:error, "Failed to send message.")}
    end
  end

  def handle_info({:message, id}, socket) do
    if id == socket.assigns.user["id"] do
      {:noreply, socket |> put_flash(:info, "You have a new message!")}
    else
      {:noreply, socket}
    end
  end

  def render(assigns) do
    assigns =
      assign(
        assigns,
        :messages,
        Swipex.Chat.get_messages(assigns.user["id"], assigns.recipient["id"])
      )

    ~H"""
    <a href="/profile" class="text-blue-500">Back to profile</a>
    <h1 class="text-4xl mb-2">Chat with <%= @recipient["name"] %></h1>
    <hr />
    <div class="flex flex-col mt-4">
      <%= for message <- @messages do %>
        <div class="flex flex-row mb-2">
          <div class={"p-2 rounded-lg #{
            if message["from"] == @user["id"], do: "bg-blue-600 text-white ml-auto", else: "bg-gray-200"
          }"}>
            <%= message["content"] %>
          </div>
        </div>
      <% end %>
      <form phx-submit="send" class="flex flex-row gap-2">
        <input type="text" name="content" placeholder="Message" class="flex-1" />
        <input type="submit" value="Send" class="bg-blue-500 text-white rounded-lg p-2" />
      </form>
    </div>
    """
  end
end
