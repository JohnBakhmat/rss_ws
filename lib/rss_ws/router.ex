defmodule RssWs.Router do
  use Plug.Router

  plug(:match)
  plug(:dispatch)

  get "/" do
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
    {ok, data} = conn.body_params |> parse_url()

    case ok do
      :error ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(400, Poison.encode!(data))
    end
  end


  defp parse_url(body) do
    case body do
      %{"url" => url} -> {:ok, url}
      _ -> {:error, "Wrong body structure"}
    end
  end
end
