defmodule SwipexWeb.ProfileLive do
  use SwipexWeb, :live_view
  alias Phoenix.PubSub
  alias SwipexWeb.ProfileLive.EditForm

  def mount(_params, session, socket) do
    if Map.has_key?(session, "user_id") do
      PubSub.subscribe(Swipex.PubSub, "swipex")
      {:ok, socket}
    else
      {:ok,
       socket
       |> put_flash(:error, "You must be logged in to access this page.")
       |> redirect(to: "/login")}
    end
  end

  def handle_event("import", %{"id" => id}, socket) do
    id = String.to_integer(id)
    conn = Bolt.Sips.conn()

    case Bolt.Sips.query(conn, "MATCH (u:User {id: $id}) RETURN u", %{id: id}) do
      {:ok, response} ->
        user = get_user_from_response(response)

        if user == %{} do
          {:noreply, put_flash(socket, :error, "Invalid user ID.")}
        else
          PubSub.broadcast(Swipex.PubSub, "swipex", {:user_changed, user})
          {:noreply, assign(socket, :user, user) |> put_flash(:info, "User imported!")}
        end

      {:error, _error} ->
        {:noreply, put_flash(socket, :error, "Invalid user ID.")}
    end
  end

  def handle_event("save", %{"name" => name, "bio" => bio}, socket) do
    conn = Bolt.Sips.conn()

    Bolt.Sips.transaction(conn, fn conn ->
      # Create a new user if one doesn't exist
      Bolt.Sips.query(conn, "MERGE (u:User {id: $id}) RETURN u", %{id: socket.assigns.user.id})
      # Update the fields
      Bolt.Sips.query(conn, "MATCH (u:User {id: $id}) SET u.bio = $bio RETURN u", %{
        id: socket.assigns.user.id,
        bio: bio
      })

      Bolt.Sips.query(conn, "MATCH (u:User {id: $id}) SET u.avatar = $avatar RETURN u", %{
        id: socket.assigns.user.id,
        avatar: socket.assigns.user.avatar
      })

      Bolt.Sips.query(conn, "MATCH (u:User {id: $id}) SET u.name = $name RETURN u", %{
        id: socket.assigns.user.id,
        name: name
      })
    end)

    user =
      Bolt.Sips.query!(conn, "MATCH (u:User {id: $id}) RETURN u", %{id: socket.assigns.user.id})
      |> get_user_from_response()

    PubSub.broadcast(Swipex.PubSub, "swipex", {:new_user, user})

    {:noreply, assign(socket, :user, user) |> put_flash(:info, "User updated!")}
  end

  def handle_event("like", %{"potential-match" => potential_match_id}, socket) do
    conn = Bolt.Sips.conn()

    # Create a relationship between the current user and the potential match
    Bolt.Sips.query!(
      conn,
      """
      MATCH (u1:User {id: $id1})
      MATCH (u2:User {id: $id2})
      MERGE (u1)-[:LIKES]->(u2)
      """,
      %{
        id1: socket.assigns.user.id,
        id2: String.to_integer(potential_match_id)
      }
    )

    # Check if the other user has liked the current user.
    match =
      Bolt.Sips.query!(
        conn,
        """
        MATCH (u1:User {id: $id1})
        MATCH (u2:User {id: $id2})
        MATCH (u1)-[r:LIKES]->(u2)
        RETURN u1, u2
        """,
        %{
          id1: String.to_integer(potential_match_id),
          id2: socket.assigns.user.id
        }
      )

    unless match.results == [] do
      [u1] = Bolt.Sips.Response.fetch!(match, "u1")
      [u2] = Bolt.Sips.Response.fetch!(match, "u2")

      PubSub.broadcast(Swipex.PubSub, "swipex", {:match, u1.properties["id"]})
      PubSub.broadcast(Swipex.PubSub, "swipex", {:match, u2.properties["id"]})
    end

    {:noreply, assign(socket, :potential_match, potential_match_id)}
  end

  def handle_event("dislike", %{"potential-match" => potential_match_id}, socket) do
    conn = Bolt.Sips.conn()

    # Create a relationship between the current user and the potential match
    Bolt.Sips.query!(
      conn,
      """
      MATCH (u1:User {id: $id1})
      MATCH (u2:User {id: $id2})
      MERGE (u1)-[:DISLIKES]->(u2)
      """,
      %{
        id1: socket.assigns.user.id,
        id2: String.to_integer(potential_match_id)
      }
    )

    {:noreply, assign(socket, :potential_match, potential_match_id)}
  end

  def handle_info({:new_user, user}, socket) do
    # Force re-rendering of the page
    {:noreply, put_flash(socket, :info, "#{user.name} has arrived!")}
  end

  def handle_info({:match, uid}, socket) do
    if socket.assigns.user.id == uid do
      {:noreply, put_flash(socket, :info, "You have a new match!")}
    else
      {:noreply, socket}
    end
  end

  def handle_info({:user_changed, user}, socket) do
    if socket.assigns.user.id == user.id do
      {:noreply, put_flash(socket, :info, "Welcome back #{user.name}!")}
    else
      {:noreply, socket}
    end
  end

  def render(assigns) do
    assigns = assign(assigns, :potential_match, get_potential_match(assigns.user["id"]))
    assigns = assign(assigns, :matches, get_matches(assigns.user["id"]))

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
    <hr />
    <div class="mt-3 flex flex-col gap-4">
      <h1 class="text-5xl">Your matches</h1>
      <div class="flex gap-3">
        <%= if @matches == [] do %>
          <p>No matches yet!</p>
        <% end %>
        <%= for match <- @matches do %>
          <div class="flex flex-col gap-3">
            <p class="text-center"><%= match["name"] %></p>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  defp get_potential_match(id) do
    conn = Bolt.Sips.conn()

    # Get all users that don't have any relationship with the current user
    Bolt.Sips.query!(
      conn,
      """
      MATCH (u2:User {id: $id})
      MATCH (u:User)
      WHERE NOT (u2)-[:LIKES]->(u) AND NOT (u2)-[:DISLIKES]->(u)
      AND u <> u2
      RETURN u LIMIT 1
      """,
      %{id: id}
    )
    |> Map.get(:results)
    |> Enum.map(&Map.get(&1, "u"))
    |> Enum.map(&get_user_from_response/1)
    |> List.first()
  end

  defp get_matches(id) do
    conn = Bolt.Sips.conn()

    # Get all users that like the current user
    Bolt.Sips.query!(
      conn,
      """
      MATCH (u2:User {id: $id})
      MATCH (u:User)
      WHERE (u2)-[:LIKES]->(u) AND (u)-[:LIKES]->(u2)
      AND u <> u2
      RETURN u
      """,
      %{id: id}
    )
    |> Map.get(:results)
    |> Enum.map(&Map.get(&1, "u"))
    |> Enum.map(&get_user_from_response/1)
  end

  defp get_user_from_response(%Bolt.Sips.Types.Node{} = node) do
    node
    |> Map.get(:properties)
    |> Map.new(fn {k, v} -> {String.to_atom(k), v} end)
  end

  defp get_user_from_response(response) do
    case response
         |> Bolt.Sips.Response.first() do
      nil ->
        %{}

      user ->
        user
        |> Map.get("u")
        |> get_user_from_response()
    end
  end
end
