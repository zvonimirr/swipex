defmodule Swipex.User do
  def register(name, password) do
    conn = Bolt.Sips.conn()
    id = UUID.uuid4()

    Bolt.Sips.query(conn, "CREATE (u:User {id: $id, name: $name, password: $password})", %{
      id: id,
      name: name,
      password: password
    })
  end

  def login(name, password) do
    conn = Bolt.Sips.conn()

    with {:ok, %Bolt.Sips.Response{results: [%{"u" => %{properties: user}}]}} <-
           Bolt.Sips.query(conn, "MATCH (u:User {name: $name, password: $password}) RETURN u", %{
             name: name,
             password: password
           }) do
      {:ok, user}
    else
      _ -> {:error, "Invalid name or password."}
    end
  end

  def get_user_by_id(id) do
    conn = Bolt.Sips.conn()

    with {:ok, %Bolt.Sips.Response{results: [%{"u" => %{properties: user}}]}} <-
           Bolt.Sips.query(conn, "MATCH (u:User {id: $id}) RETURN u", %{id: id}) do
      {:ok, user}
    else
      _ -> {:error, "User not found."}
    end
  end
end
