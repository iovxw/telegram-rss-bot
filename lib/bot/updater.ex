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
        case parse_rss(body) do
          {:ok, feed} ->
            update_message = feed.entries |> Enum.reduce([msg: "*#{feed.title}*\n", num: 0],
            fn(entry, acc) ->
              t = parse_datetime(entry.updated)
              now = Timex.Date.now()
              if Timex.Date.diff(t, now, :secs) < (5 * 60) do
                [msg: acc[:msg] <> "[#{entry.title}](#{entry.link})\n", num: acc[:num]+1]
              else
                acc
              end
            end)
            if update_message[:num] != 0 do
              {:ok, update_message[:msg]}
            else
              nil
            end
          {:error, _} ->
            nil
        end
      {:error, _} ->
        nil
    end
  end

  def parse_rss(rss) do
    try do
      case FeederEx.parse(rss) do
        {:ok, feed, _} ->
          {:ok, feed}
        {:error, _} = err ->
          err
      end
    rescue
      err ->
        {:error, err}
    end
  end

  def parse_datetime(time, format \\ "{RFC1123}") do
    case Timex.DateFormat.parse(time, format) do
      {:ok, date} -> date
      _ -> Timex.Date.zero
    end
  end

  def http_get_body(url) do
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
