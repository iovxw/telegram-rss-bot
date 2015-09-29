defmodule RSSBot do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      supervisor(Task.Supervisor, [[name: RSSBot.TaskSupervisor]]),
      worker(Task, [RSSBot.Serve, :pull_updates, []])
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: RSSBot.Supervisor)
  end
end