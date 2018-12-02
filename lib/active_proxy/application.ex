defmodule ActiveProxy.Application do
  use Application
  require Logger

  def start(_type, _args) do
    children = [
      {Task.Supervisor, name: ActiveProxy.TaskSupervisor},
      Supervisor.child_spec({Task, fn -> ActiveProxy.Proxy.listen(8080) end}, restart: :permanent)
    ]

    Logger.info("Starting Proxy...")

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
