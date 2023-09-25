defmodule RssWs.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      RssWs.Endpoint
    ]
    opts = [strategy: :one_for_one, name: RssWs.Supervisor]

    Supervisor.start_link(children, opts)
  end
end
