defmodule RSSBot.Serve do
  alias Nadia.Model.Message
  alias Nadia.Model.User

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

  def handle_message(%Message{chat: chat, text: <<"/rss", value :: bitstring>>}) do
    Nadia.send_message(chat.id, value)
  end

  def handle_message(_), do: :ok
end
