defmodule Swipex.User do
  def register(name, password) do
    conn = Bolt.Sips.conn()
    id = UUID.uuid4()

    Bolt.Sips.query(conn, "CREATE (u:User {id: $id, name: $name, password: $password})", %{
      id: id,
      name: name,
      password: Bcrypt.hash_pwd_salt(password)
    })
  end

  def login(name, password) do
    conn = Bolt.Sips.conn()

    with {:ok, %Bolt.Sips.Response{results: [%{"u" => %{properties: user}}]}} <-
           Bolt.Sips.query(conn, "MATCH (u:User {name: $name }) RETURN u", %{
             name: name
           }),
         true <- Bcrypt.verify_pass(password, user["password"]) do
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

  def get_potential_match(id) do
    conn = Bolt.Sips.conn()

    with {:ok,
          %Bolt.Sips.Response{
            results: [
              %{
                "u" => %{properties: potential_match}
              }
            ]
          }} <-
           Bolt.Sips.query(
             conn,
             """
             MATCH (u2:User {id: $id})
             MATCH (u:User)
             WHERE NOT (u2)-[:LIKES]->(u) AND NOT (u2)-[:DISLIKES]->(u)
             AND u <> u2
             RETURN u LIMIT 1
             """,
             %{id: id}
           ),
         {:ok, m} <- get_user_by_id(Map.get(potential_match, "id")) do
      m
    else
      _ -> nil
    end
  end

  def like(id, match_id) do
    conn = Bolt.Sips.conn()

    with {:ok, _} <-
           Bolt.Sips.query(
             conn,
             """
             MATCH (u1:User {id: $id})
             MATCH (u2:User {id: $match_id})
             CREATE (u1)-[:LIKES]->(u2)
             """,
             %{id: id, match_id: match_id}
           ),
         should_notify <- has_matched(id, match_id) do
      {:ok, should_notify}
    else
      _ -> {:error, "Failed to like user."}
    end
  end

  def dislike(id, match_id) do
    conn = Bolt.Sips.conn()

    with {:ok, _} <-
           Bolt.Sips.query(
             conn,
             """
             MATCH (u1:User {id: $id})
             MATCH (u2:User {id: $match_id})
             CREATE (u1)-[:DISLIKES]->(u2)
             """,
             %{id: id, match_id: match_id}
           ) do
      :ok
    else
      _ -> :error
    end
  end

  def get_matches(id) do
    conn = Bolt.Sips.conn()

    with {:ok, %Bolt.Sips.Response{results: results}} <-
           Bolt.Sips.query(
             conn,
             """
             MATCH (u2:User {id: $id})
             MATCH (u:User)
             WHERE (u2)-[:LIKES]->(u) AND (u)-[:LIKES]->(u2)
             AND u <> u2
             RETURN u
             """,
             %{id: id}
           ),
         results <- Enum.map(results, &Map.get(&1, "u")),
         matches <- Enum.map(results, &Map.get(&1, :properties)) do
      matches
    else
      _ -> []
    end
  end

  def has_matched(id, match_id) do
    conn = Bolt.Sips.conn()

    with {:ok, %Bolt.Sips.Response{results: results}} <-
           Bolt.Sips.query(
             conn,
             """
             MATCH (u1:User {id: $id})
             MATCH (u2:User {id: $match_id})
             MATCH (u1)-[r:LIKES]->(u2)
             RETURN u1, u2
             """,
             %{id: id, match_id: match_id}
           ) do
      results != []
    else
      _ -> false
    end
  end
end
