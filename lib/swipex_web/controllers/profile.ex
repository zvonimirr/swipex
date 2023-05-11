defmodule SwipexWeb.Profile do
  use SwipexWeb, :verified_routes
  import Plug.Conn
  import Phoenix.Controller

  def on_mount(:current_user, _params, session, socket) do
    # Generate user info if not present in the session
    if !Map.has_key?(session, :user) do
      # Generate a random user from a random number
      user_id = System.unique_integer([:positive])

      {:cont,
       Phoenix.Component.assign_new(socket, :user, fn ->
         %{
           id: user_id,
           name: "User #{user_id}",
           avatar: "https://api.dicebear.com/6.x/pixel-art/svg?seed=#{user_id}&background=%23fff",
           bio: ""
         }
       end)}
    else
      {:cont, Phoenix.Component.assign(socket, :user, session.user)}
    end
  end
end
