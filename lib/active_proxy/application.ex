defmodule ActiveProxy.Application do
  use Application
  require Logger

  def start(_type, _args) do
    children = [
      {Plug.Cowboy, scheme: :http, plug: ActiveProxy.Proxy, options: [port: 8080]}
    ]

    Logger.info("Starting application...")

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
