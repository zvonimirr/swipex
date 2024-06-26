defmodule SwipexWeb.PageController do
  alias Phoenix.PubSub
  use SwipexWeb, :controller

  def index(conn, _params) do
    case get_session(conn, :user_id) do
      nil -> render(conn, :index)
      _ -> redirect(conn, to: "/profile")
    end
  end

  def register(conn, _params) do
    case get_session(conn, :user_id) do
      nil -> render(conn, :register)
      _ -> redirect(conn, to: "/profile")
    end
  end

  def do_register(conn, %{
        "name" => name,
        "password" => password
      }) do
    with true <- String.length(name) > 0,
         true <- String.length(password) > 0,
         {:ok, _} <- Swipex.User.register(name, password) do
      PubSub.broadcast(Swipex.PubSub, "swipex", {:new_user, name})

      conn
      |> put_flash(:info, "Registered successfully!")
      |> redirect(to: "/login")
    else
      _ -> do_register(conn, %{})
    end
  end

  def do_register(conn, _params) do
    conn
    |> put_flash(:error, "Could not register. Please try again.")
    |> redirect(to: "/register")
  end

  def login(conn, _params) do
    render(conn, :login)
  end

  def do_login(conn, %{
        "name" => name,
        "password" => password
      }) do
    with true <- String.length(name) > 0,
         true <- String.length(password) > 0,
         {:ok, user} <- Swipex.User.login(name, password) do
      conn
      |> put_flash(:info, "Logged in successfully!")
      |> put_session(:user_id, user["id"])
      |> redirect(to: "/")
    else
      _ -> do_login(conn, %{})
    end
  end

  def do_login(conn, _params) do
    conn
    |> put_flash(:error, "Invalid name or password.")
    |> redirect(to: "/login")
  end

  def logout(conn, _params) do
    case get_session(conn, :user_id) do
      nil ->
        redirect(conn, to: "/")

      _ ->
        conn
        |> delete_session(:user_id)
        |> put_flash(:info, "Logged out successfully!")
        |> redirect(to: "/login")
    end
  end
end
