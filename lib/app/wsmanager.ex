# WSManager determines the type of update and allows us to write the processing of any type we need in the commands.ex

defmodule Bleroma.WSManager do
  use GenServer

  alias Bleroma.Commands
  alias Bleroma.CommandsLI
  require Logger

  import Storage
  import Bleroma.Utils
  alias Bleroma.Utils
  import StateManager

  # Server
  # ----------------------------------------------------------------------------

  def start_link() do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @impl true
  def init(:ok) do
    Logger.log(:info, "Started WSM")
    app = Hunter.Application.load_credentials("bleroma")
    Logger.log(:info, "Loaded application #{inspect(app)}")

    storage = Storage.init()
    all_bearers = Storage.get_all(storage)
    websocks = Enum.map(all_bearers, fn [tg, bearer] ->
      {:ok, conn} = StateManager.get_conn(tg); 
      Bleroma.Websocks.start_link({tg, conn})
    end)

    {:ok, %{app: app, storage: storage, websocks: websocks}}
  end

  @impl true
  def handle_cast(update, state) do
    {:noreply, state}
  end

  # Client
  # ----------------------------------------------------------------------------

  def match(message) do
    GenServer.cast(__MODULE__, message)
  end
end
