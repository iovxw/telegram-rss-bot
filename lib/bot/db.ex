defmodule RSSBot.DB do
  def start_link(path, opts \\ []) do
    opts = opts |> Keyword.put(:name, RSSBot.DBServer)
    GenServer.start_link(__MODULE__, path, opts)
  end

  def init(path), do: Exleveldb.open(path)

  def put(key, value) do
    GenServer.call(RSSBot.DBServer, {:put, key, value})
  end

  def get(key) do
    GenServer.call(RSSBot.DBServer, {:get, key})
  end

  def handle_call({:put, key, value}, _, db_ref) do
    result = db_ref |> Exleveldb.put(key, value)
    {:reply, result, db_ref}
  end

  def handle_call({:get, key}, _, db_ref) do
    result = db_ref |> Exleveldb.get(key)
    {:reply, result, db_ref}
  end
end
