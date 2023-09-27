defmodule RssWs.Router do
  use Plug.Router

  plug(:match)
  plug(:dispatch)

  get "/" do
    {:ok, redis_conn} = Redix.start_link("redis://localhost:6379/3", name: :redix)
    Redix.command(redis_conn, ["SET", "test", "foo"])

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Poison.encode!(message()))
  end

  defp message do
    %{
      response_type: "in_channel",
      text: "Hello from BOT :)"
    }
  end

  get "/ping" do
    send_resp(conn, 200, "pong!")
  end

  defmodule OpenReq do
    @derive [Poison.Encoder]
    defstruct [:url]
  end

  post "/open" do
    redis_conn =
      case Redix.start_link("redis://localhost:6379/3") do
        {:ok, redis_conn} ->
          redis_conn
        {:error, {:already_started, redis_conn}} ->
          redis_conn
        {:error, err} ->
          respond(conn, 500, "Error connection to Redis")
      end

    conn.body_params
    |> parse_url
    |> case do
      {:error, error} ->
        respond(conn, 400, Poison.encode!(error))

      {:ok, data} ->
        Redix.command(redis_conn, ["GET", data])
        |> case do
          {:ok, url_cache} ->
            IO.inspect("Cache hit")
            respond(conn, 200, Poison.encode!(%{websocket_url: url_cache}))

          {:ok, nil} ->
            IO.inspect("Cache didnt hit")
            ws_url = "ws://" <> data
            Redix.command(redis_conn, ["SET", data, ws_url])
            respond(conn, 200, Poison.encode!(%{websocket_url: ws_url}))

          {_, err} ->
            respond(conn, 500, err)
        end
    end

    conn
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
