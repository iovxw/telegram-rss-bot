defmodule RSSBot.Serve do
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
      {:error, %Nadia.Model.Error{reason: :timeout}} ->
        false
    end
    :timer.sleep(200)
    pull_updates(offset)
  end

  def handle_message(%Message{chat: chat, text: "/ping"}) do
    Nadia.send_message(chat.id, "pong")
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

  def handle_message(%Message{chat: chat, text: <<"/sub ", value :: bitstring>>}) do
    case RSSBot.DB.subscribe(chat.id, value) do
      :ok ->
        Nadia.send_message(chat.id, value <> " 订阅成功")
      :already_subscribed ->
        Nadia.send_message(chat.id, value <> " 已经订阅过了")
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
