defmodule Swipex.Chat do
  def send_message(from, to, content) do
    conn = Bolt.Sips.conn()

    Bolt.Sips.query(
      conn,
      """
      MATCH (u1:User {id: $from})
      MATCH (u2:User {id: $to})
      CREATE (u1)-[:MESSAGE {content: $content, timestamp: $time, from: $from, to: $to}]->(u2)
      """,
      %{
        from: from,
        to: to,
        content: content,
        time: DateTime.utc_now()
      }
    )
  end

  def get_messages(from, to) do
    conn = Bolt.Sips.conn()

    {:ok, %Bolt.Sips.Response{results: sent}} =
      Bolt.Sips.Query.query(
        conn,
        """
        MATCH ()-[sent:MESSAGE { from: $from, to: $to }]-()
        RETURN sent
        """,
        %{from: from, to: to}
      )

    {:ok, %Bolt.Sips.Response{results: received}} =
      Bolt.Sips.Query.query(
        conn,
        """
        MATCH ()-[received:MESSAGE { from: $to, to: $from }]->()
        RETURN received
        """,
        %{from: from, to: to}
      )

    sent_messages =
      sent
      |> Enum.map(&Map.get(&1, "sent"))
      |> Enum.uniq_by(&Map.get(&1, :id))
      |> Enum.map(&Map.get(&1, :properties))

    received_messages =
      received
      |> Enum.map(&Map.get(&1, "received"))
      |> Enum.uniq_by(&Map.get(&1, :id))
      |> Enum.map(&Map.get(&1, :properties))

    Enum.concat(sent_messages, received_messages)
    |> Enum.sort(&(DateTime.compare(Map.get(&1, "timestamp"), Map.get(&2, "timestamp")) != :gt))
  end
end
