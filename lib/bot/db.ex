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

  def delete(key) do
    GenServer.cast(RSSBot.DBServer, {:delete, key})
  end

  def handle_call({:put, key, value}, _, db_ref) do
    result = db_ref |> Exleveldb.put(key, value)
    {:reply, result, db_ref}
  end

  def handle_call({:get, key}, _, db_ref) do
    result = db_ref |> Exleveldb.get(key)
    {:reply, result, db_ref}
  end

  def handle_cast({:delete, key}, db_ref) do
    db_ref |> Exleveldb.delete(key)
    {:noreply, db_ref}
  end

  def get_rss_list do
    case get("rss_list") do
      {:ok, list} ->
        String.split(list)
      :not_found ->
        []
    end
  end

  def get_rss_list(chat_id) do
    id_binary = <<chat_id::unsigned-integer-size(64)>>
    case get(id_binary) do
      {:ok, list} ->
        String.split(list)
      :not_found ->
        []
    end
  end

  def subscribe(chat_id, rss_url) do
    id_binary = <<chat_id::unsigned-integer-size(64)>>
    already_subscribed = case get(id_binary) do
      {:ok, value} ->
        list = String.split(value)
        unless list |> Enum.member?(rss_url) do
          put(id_binary, value <> " " <> rss_url)
          false
        else
          true
        end
      :not_found ->
        put(id_binary, rss_url)
        false
    end
    # 已经订阅过的话，跳过
    if already_subscribed do
      :already_subscribed
    else
      case get("rss_list") do
        {:ok, value} ->
          list = String.split(value)
          unless list |> Enum.member?(rss_url) do
            put("rss_list", value <> " " <> rss_url)
          end
        :not_found ->
          put("rss_list", rss_url)
      end
      case get(rss_url) do
        {:ok, value} ->
          put(rss_url, value <> id_binary)
        :not_found ->
          put(rss_url, id_binary)
      end
      :ok
    end
  end

  def unsubscribe(chat_id, rss_url) do
    id_binary = <<chat_id::unsigned-integer-size(64)>>
    case get(id_binary) do
      {:ok, value} ->
        list = String.split(value)
        if list |> Enum.member?(rss_url) do
          list = list |> List.delete(rss_url)
          put(id_binary, list |> Enum.join(" "))

          {:ok, value} = get(rss_url)
          list = value |> split_binary(8)
          if length(list) == 1 do
            # 最后一个订阅者退订，直接删除这个 RSS 的数据
            {:ok, value} = get("rss_list")
            list = String.split(value)
            list = list |> List.delete(rss_url)
            put("rss_list", list |> Enum.join(" "))

            delete(rss_url)
            delete("old_" <> rss_url)
          else
            list = list |> List.delete(id_binary)
            put(id_binary, list |> Enum.join())
          end
          :ok
        else
          :no_subscription
        end
      :not_found ->
        :no_subscription
    end
  end

  defp split_binary(bin, n, list) when byte_size(bin) <= n do
    [bin|list]
  end

  defp split_binary(bin, n, list \\ []) do
    <<part::binary-size(n), bin::binary>> = bin
    split_binary(bin, n, [part|list])
  end

  def get_subscribers(rss_url) do
    case get(rss_url) do
      {:ok, value} ->
        list = value |> split_binary(8)
        list |> Enum.map fn(id_binary) ->
          <<id::unsigned-integer-size(64)>> = id_binary
          id
        end
      :not_found ->
        []
    end
  end
end
