defmodule RssWs.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      RssWs.Endpoint
    ]
    opts = [strategy: :one_for_one, name: RssWs.Supervisor]

    unless Mix.env == :prod do
      Envy.auto_load
    end

    Supervisor.start_link(children, opts)
  end
end
