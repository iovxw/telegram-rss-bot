defmodule RSSBot.Updater do
  def pull_updates do
    RSSBot.DB.get_rss_list() |> Enum.each fn(rss) ->
      case get_rss_updates(rss) do
        {:ok, updates} ->
          rss |> RSSBot.DB.get_subscribers() |> Enum.each fn(chat_id) ->
            Nadia.send_message(chat_id, updates,
            [parse_mode: "markdown", disable_web_page_preview: true])
          end
        nil ->
          nil
      end
    end
    :timer.sleep(5 * 60 * 1000)
    pull_updates
  end

  defp get_rss_updates(rss_url) do
    case http_get_body(rss_url) do
      {:ok, body} ->
        case FeederEx.parse(body) do
          {:ok, feed, _} ->
            entries = feed.entries |> Enum.reject fn(entry) ->
              t = parse_datetime(entry.updated)
              now = Timex.Date.now()
              if Timex.Date.diff(t, now, :secs) < (5 * 60) do
                false
              else
                true
              end
            end
            if entries != [] do
              update_message = entries |> Enum.reduce("*#{feed.title}*\n",
              fn(update, acc) ->
                acc <> "[#{update.title}](#{update.link})\n"
              end)
              {:ok, update_message}
            else
              nil
            end
          {:error, err} ->
            IO.inspect err
            nil
        end
      {:error, _} ->
        nil
    end
  end

  def parse_datetime(time, format \\ "{RFC1123}") do
    case Timex.DateFormat.parse(time, format) do
      {:ok, date} -> date
      _ -> 0
    end
  end

  defp http_get_body(url) do
    case HTTPoison.get(url) do
      {:ok, response} ->
        case response.status_code do
          c when c == 301 or c == 302 ->
            http_get_body(response.headers["Location"])
          200 ->
            {:ok, response.body}
        end
      {:error, _} = err ->
        err
    end
  end
end
