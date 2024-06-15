defmodule SwipexWeb.PageController do
  use SwipexWeb, :controller

  def index(conn, _params) do
    render(conn, :index)
  end

  def register(conn, _params) do
    render(conn, :register)
  end

  def do_register(conn, %{
        "name" => name,
        "password" => password
      }) do
    with true <- String.length(name) > 0,
         true <- String.length(password) > 0,
         {:ok, _} <- Swipex.User.register(name, password) do
      conn
      |> put_flash(:info, "Registered successfully!")
      |> redirect(to: "/login")
    else
      _ -> do_register(conn, %{})
    end
  end

  def do_register(conn, _params) do
    conn
    |> put_flash(:error, "Invalid name or password.")
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
end
