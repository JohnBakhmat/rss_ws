defmodule RssWs.Router do
  use Plug.Router

  plug(:match)
  plug(:dispatch)

  get "/ping" do
    send_resp(conn, 200, "pong!")
  end

  post "/open" do
    redis_url = System.get_env("REDIS_URL")

    redis_conn =
      case Redix.start_link(redis_url) do
        {:ok, redis_conn} ->
          redis_conn

        {:error, {:already_started, redis_conn}} ->
          redis_conn

        {:error, _} ->
          conn |> respond(500, "Error connection to Redis")
      end

    conn.body_params
    |> parse_url
    |> case do
      {:error, error} ->
        conn |> respond(400, Poison.encode!(error))

      {:ok, data} ->
        Redix.command(redis_conn, ["GET", data])
        |> case do
          {:ok, nil} ->
            IO.inspect("Cache didnt hit")
            ws_url = "ws://" <> data
            Redix.command(redis_conn, ["SET", data, ws_url])
            conn |> respond(200, Poison.encode!(%{websocket_url: ws_url}))

          {:ok, url_cache} ->
            IO.inspect("Cache hit")
            conn |> respond(200, Poison.encode!(%{websocket_url: url_cache}))

          {:error, _} ->
            conn |> respond(500, "Erorr")
        end
    end
  end

  defp respond(conn, status, message) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(status, message)
  end

  defp parse_url(body) do
    case body do
      %{"url" => url} -> {:ok, url}
      _ -> {:error, "Wrong body structure"}
    end
  end
end
