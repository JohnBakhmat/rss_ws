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
    {:ok, redis_conn} = Redix.start_link("redis://localhost:6379/3", name: :redix)
    {ok, data} = conn.body_params |> parse_url()

    if ok == :error do
      conn
      |> put_resp_content_type("application/json")
      |> send_resp(400, Poison.encode!(data))
    end

    {ok, url_cache} = Redix.command(redis_conn, ["GET", data])

    if ok == :ok and url_cache != nil do
      IO.inspect("Cache hit")

      conn
      |> put_resp_content_type("application/json")
      |> send_resp(200, Poison.encode!(%{websocket_url: url_cache}))
    else
      IO.inspect("Cache didnt hit")

      ws_url = "ws://" <> data
      Redix.command(redis_conn, ["SET", data, ws_url])

      conn
      |> put_resp_content_type("application/json")
      |> send_resp(200, Poison.encode!(%{websocket_url: ws_url}))
    end
  end

  defp parse_url(body) do
    case body do
      %{"url" => url} -> {:ok, url}
      _ -> {:error, "Wrong body structure"}
    end
  end
end
