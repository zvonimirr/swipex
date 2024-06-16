defmodule SwipexWeb.Profile do
  use SwipexWeb, :verified_routes

  def on_mount(:current_user, _params, session, socket) do
    case Swipex.User.get_user_by_id(Map.get(session, "user_id")) do
      {:ok, user} -> {:cont, Phoenix.Component.assign(socket, :user, user)}
      {:error, _} -> {:cont, Phoenix.Component.assign(socket, :user, nil)}
    end
  end
end
