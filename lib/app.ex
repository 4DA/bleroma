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
    ]

    opts = [strategy: :one_for_one, name: Bleroma.Supervisor]
    {:ok, sv_pid} = Supervisor.start_link(children, opts)

    {_, matcher_pid, _, _} = List.keyfind(Supervisor.which_children(sv_pid), Bleroma.Matcher, 0)
    Logger.log(:info, "sv: #{inspect(sv_pid)} | children: #{inspect(Supervisor.which_children(sv_pid))}")
    
    wsm = Supervisor.start_child(sv_pid,
      %{id: Bleroma.WSManager,
        start: {Bleroma.WSManager, :start_link, [matcher_pid]}
      })

    {:ok, sv_pid}
  end
end
