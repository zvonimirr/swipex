defmodule SwipexWeb.ProfileLive do
  use SwipexWeb, :live_view
  alias Phoenix.PubSub

  def mount(_params, %{"user_id" => _user_id}, socket) do
    PubSub.subscribe(Swipex.PubSub, "swipex")
    {:ok, socket}
  end

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> put_flash(:error, "You must be logged in to access this page.")
     |> redirect(to: "/login")}
  end

  def handle_event("like", %{"potential-match" => match_id}, socket) do
    case Swipex.User.like(socket.assigns.user["id"], match_id) do
      {:ok, true} ->
        PubSub.broadcast(Swipex.PubSub, "swipex", {:match, match_id})
        PubSub.broadcast(Swipex.PubSub, "swipex", {:match, socket.assigns.user["id"]})
        {:noreply, socket}

      {:ok, false} ->
        {:noreply, socket}

      {:error, error} ->
        {:noreply, socket |> put_flash(:error, error)}
    end
  end

  def handle_event("dislike", %{"potential-match" => match_id}, socket) do
    case Swipex.User.dislike(socket.assigns.user["id"], match_id) do
      :ok ->
        {:noreply, socket |> put_flash(:info, "Disliked user.")}

      :error ->
        {:noreply, socket |> put_flash(:error, "Failed to dislike user.")}
    end
  end

  def handle_info({:new_user, name}, socket) do
    {:noreply, put_flash(socket, :info, "#{name} has arrived!")}
  end

  def handle_info({:match, id}, socket) do
    if id == socket.assigns.user["id"] do
      {:noreply, socket |> put_flash(:info, "You have a new match!")}
    else
      {:noreply, socket}
    end
  end

  def render(assigns) do
    assigns =
      assign(assigns, :potential_match, Swipex.User.get_potential_match(assigns.user["id"]))

    assigns = assign(assigns, :matches, Swipex.User.get_matches(assigns.user["id"]))

    ~H"""
    <div class="flex gap-4 justify-between w-full mb-3">
      <div class="flex flex-col gap-3">
        <h1 class="text-4xl"><%= @user["name"] %></h1>
        <p>Hey there, <%= @user["name"] %>, this is your profile page.</p>
        <hr />
      </div>
      <%= if @potential_match do %>
        <div class="flex flex-col gap-3">
          <p class="text-2xl">Let's swipe!</p>
          <div class="flex flex-col gap-3">
            <p><%= @potential_match["name"] %></p>
            <div class="flex gap-3">
              <button
                phx-click="like"
                phx-value-potential-match={@potential_match["id"]}
                class="bg-green-300 text-white rounded-md p-3"
              >
                Like
              </button>
              <button
                phx-click="dislike"
                phx-value-potential-match={@potential_match["id"]}
                class="bg-red-300 text-white rounded-md p-3"
              >
                Dislike
              </button>
            </div>
          </div>
        </div>
      <% else %>
        <div class="flex flex-col">
          <p class="text-2xl">No more potential matches!</p>
        </div>
      <% end %>
    </div>
    <div class="mt-3 flex flex-col gap-4">
      <h1 class="text-5xl">Your matches</h1>
      <div class="flex gap-3">
        <%= if @matches == [] do %>
          <p>No matches yet!</p>
        <% end %>
        <%= for match <- @matches do %>
          <div class="flex flex-col gap-3">
            <a href={"/chat/#{match["id"]}"} class="text-blue-400 hover:underline">
              <%= match["name"] %>
            </a>
          </div>
        <% end %>
      </div>
    </div>
    """
  end
end
