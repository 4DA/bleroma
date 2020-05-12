# WSManager determines the type of update and allows us to write the processing of any type we need in the commands.ex

defmodule App.WSManager do
  use GenServer

  alias App.Commands
  alias App.CommandsLI
  require Logger

  import Storage
  import Bleroma.Utils
  alias Bleroma.Utils

  # Server
  # ----------------------------------------------------------------------------

  def start_link do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @impl true
  def init(:ok) do
    app = Hunter.Application.load_credentials("bleroma")
    Logger.log(:info, "Loaded application #{inspect(app)}")

    storage = Storage.init()
    all_bearers = Storage.get_all(storage)
    conns = Enum.map(all_bearers, fn [tg, bearer] -> Utils.new_connection(tg, bearer) end)
    Logger.log(:info, "all conns = #{inspect(conns)}")

    ws = Bleroma.Websocks.start_link(Enum.at(conns, 0))
    Logger.log(:info, "ws = #{inspect(ws)}")

    {:ok, %{app: app, storage: storage, conns: conns}}
  end

  @impl true
  def handle_cast(update, state) do
    # # Logger.log(:info, "recv msg: #{inspect(update)}")

    
    # {conn, state} = Utils.get_conn(update, state)
    # # Logger.log(:info, "home timeline: #{inspect(Hunter.home_timeline(conn))})")    

    # Logger.log(:info, "bearer: #{inspect(conn.bearer_token)}")
    # # user is not authenticated
    # if conn == nil do
    #   state = Commands.match_message(update, state)
    # else
    #   state = CommandsLI.match_message(update, state)
    # end

    

    {:noreply, state}
  end

  # Client
  # ----------------------------------------------------------------------------

  def match(message) do
    GenServer.cast(__MODULE__, message)
  end
end
