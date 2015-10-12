defmodule RSSBot.Updater do
  def pull_updates do
    RSSBot.DB.get_rss_list() |> Enum.each fn(rss) ->
      case get_rss_updates(rss) do
        {:ok, updates} ->
          rss |> RSSBot.DB.get_subscribers() |> Enum.each fn(chat_id) ->
            Nadia.send_message(chat_id, updates)
          end
        nil ->
          nil
      end
    end
    :timer.sleep(5 * 60 * 1000)
    pull_updates
  end

  defp get_rss_updates(rss_url) do
    case HTTPoison.get(rss_url) do
      {:ok, response} ->
        # TODO: 获取5分钟内的更新
        {:ok, response.body}
      {:error, _} ->
        nil
    end
  end
end
