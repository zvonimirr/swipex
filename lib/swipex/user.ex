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
end
