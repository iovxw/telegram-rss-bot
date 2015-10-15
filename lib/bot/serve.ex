defmodule RSSBot.Serve do
  require Logger
  alias Nadia.Model.Message

  def pull_updates(offset \\ -1) do
    case Nadia.get_updates(offset: offset) do
      {:ok, updates} ->
        if length(updates) > 0 do
          offset = List.last(updates).update_id + 1
          updates
          |> Enum.each(&Task.Supervisor.start_child(RSSBot.TaskSupervisor,
          RSSBot.Serve, :handle_message, [&1.message]))
        end
      {:error, %Nadia.Model.Error{reason: err}} ->
        Logger.error("Nadia.get_updates: #{err}")
    end
    :timer.sleep(200)
    pull_updates(offset)
  end

  def handle_message(%Message{chat: chat, text: "/rss"}) do
    list = RSSBot.DB.get_rss_list(chat.id)
    if list == [] do
      Nadia.send_message(chat.id, "没有订阅任何 RSS")
    else
      Nadia.send_message(chat.id,
        "*订阅的RSS列表:*\n" <> Enum.join(list, "\n"),
        [parse_mode: "markdown"])
    end
  end

  def handle_message(%Message{chat: chat, text: <<"/sub ", rss_url :: bitstring>>}) do
    case check_rss(rss_url) do
      {:ok, title} ->
        case RSSBot.DB.subscribe(chat.id, rss_url) do
          :ok ->
            Nadia.send_message(chat.id, "《" <> title <> "》订阅成功")
            if RSSBot.DB.get_subscribers(rss_url) |> length == 1 do
              # 第一个订阅者，更新一遍记录
              RSSBot.Updater.get_rss_updates(rss_url)
            end
          :already_subscribed ->
            Nadia.send_message(chat.id, "《" <> title <> "》已经订阅过了")
        end
      :not_rss ->
        Nadia.send_message(chat.id, rss_url <> " 无法获取到 RSS 内容")
      :network_error ->
        Nadia.send_message(chat.id, rss_url <> " 连接失败")
    end
  end

  defp check_rss(url) do
    case RSSBot.Updater.http_get_body(url) do
      {:ok, body} ->
        case RSSBot.Updater.parse_rss(body) do
          {:ok, feed} ->
            {:ok, feed.title}
          {:error, _} ->
            :not_rss
        end
      {:error, _} ->
        :network_error
    end
  end

  def handle_message(%Message{chat: chat, text: <<"/unsub ", value :: bitstring>>}) do
    case RSSBot.DB.unsubscribe(chat.id, value) do
      :ok ->
        Nadia.send_message(chat.id, value <> " 退订成功")
      :no_subscription ->
        Nadia.send_message(chat.id, value <> " 从未订阅过")
    end
  end

  def handle_message(_), do: :ok
end
