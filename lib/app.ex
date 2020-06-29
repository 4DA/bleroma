defmodule App do
  use Application

  require Logger
  require StateManager

  def start(_type, _args) do
    bot_name = Application.get_env(:app, :bot_name)

    unless String.valid?(bot_name) do
      IO.warn("""
      Env not found Application.get_env(:app, :bot_name)
      This will give issues when generating commands
      """)
    end

    if bot_name == "" do
      IO.warn("An empty bot_name env will make '/anycommand@' valid")
    end

    import Supervisor.Spec, warn: false
    Application.ensure_all_started(:websockex)

    children = [
      worker(Bleroma.Poller, []),
      worker(Bleroma.Matcher, []),
      worker(StateManager, []),
      worker(Cachex, [:shown_updates, []])
    ]

    opts = [strategy: :one_for_one, name: Bleroma.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
