defmodule SwipexWeb.ProfileLive do
  use SwipexWeb, :live_view
  alias SwipexWeb.ProfileLive.EditForm

  def handle_event("import", %{"id" => id}, socket) do
    id = String.to_integer(id)
    conn = Bolt.Sips.conn()

    case Bolt.Sips.query(conn, "MATCH (u:User {id: $id}) RETURN u", %{id: id}) do
      {:ok, response} ->
        user = get_user_from_response(response)

        if user == %{} do
          {:noreply, put_flash(socket, :error, "Invalid user ID.")}
        else
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

    {:noreply, assign(socket, :user, user) |> put_flash(:info, "User updated!")}
  end

  def render(assigns) do
    ~H"""
    <div class="py-12 flex flex-col gap-3">
      <h1 class="text-4xl"><%= @user.name %></h1>
      <img src={@user.avatar} class="w-32 h-32 rounded-full" />
      <p>Hey there, <%= @user.name %>, this is your profile page.</p>
      <p>Why don't you tell us something about yourself?</p>

      <div class="flex flex-col gap-3">
        <.live_component id="edit_form" module={EditForm} user={@user} />
      </div>

      <hr />

      <div class="flex flex-col gap-3">
        <p>Already have an account?</p>
        <form phx-submit="import" class="flex flex-col gap-4">
          <input type="number" name="id" placeholder="User ID" />
          <button type="submit" class="bg-blue-300 text-white rounded-md p-3">Import</button>
        </form>
      </div>
    </div>
    """
  end

  defp get_user_from_response(response) do
    case response
         |> Bolt.Sips.Response.first() do
      nil ->
        %{}

      user ->
        user
        |> Map.get("u")
        |> Map.get(:properties)
        |> Map.new(fn {k, v} -> {String.to_atom(k), v} end)
    end
  end
end
