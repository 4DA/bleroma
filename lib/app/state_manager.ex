defmodule StateManager do
  use GenServer
  require Logger
  require Bleroma.Utils
  alias Bleroma.Utils

  defstruct app: nil, storage: nil, conns: %{}, websocks: %{}

  # server
  # -------------------------------------------------------------------------

  def start_link() do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @impl true
  def init(:ok) do
    Logger.log(:info, "Started StateManager")
    {:ok, %StateManager{app: nil, storage: nil, conns: nil}} # 

    app = Hunter.Application.load_credentials("bleroma")
    storage = Storage.init()
    all_bearers = Storage.get_all(storage)

    Logger.log(:info, "All bearers: #{inspect(all_bearers)}")    

    conns = Map.new(all_bearers, fn [tg, bearer] ->
      {tg, Utils.new_connection(tg, bearer)} end)

    Logger.log(:info, "All conns: #{inspect(conns)}")    

    websocks = Map.new(all_bearers, fn [tg, bearer] ->
      {:ok, pid} = Bleroma.Websocks.start({tg, Map.get(conns, tg)})
      {tg, pid}
    end)

    Logger.log(:info, "All WS: #{inspect(websocks)}")

    {:ok, %StateManager{app: app, storage: storage, conns: conns, websocks: websocks}} # 
  end

  @impl true
  def handle_call({:get_conn, tg_user_id}, _from, state) do
    case Map.get(state.conns, tg_user_id, nil) do
      nil -> {:reply, :error, state}
      value -> {:reply, {:ok, value}, state}
    end
  end

  @impl true
  def handle_call({:add_user, tg_user_id, conn}, _from, state) do
    Storage.store_auth(state.storage, tg_user_id, conn.bearer_token)

    {:ok, pid} = Bleroma.Websocks.start({tg_user_id, conn})

    {:reply, :ok,
     %StateManager{state | conns: Map.put(state.conns, tg_user_id, conn),
                   websocks: Map.put(state.websocks, tg_user_id, pid)}}
  end

  @impl true
  def handle_call({:delete_user, tg_user_id}, _from, state) do
    Storage.delete_auth(state.storage, tg_user_id)

    pid = Map.get(state.websocks, tg_user_id)
    Process.exit(pid, :kill)
    Logger.log(:info, "Removed ws pid #{inspect(pid)}")

    Map
    {:reply, :ok,
     %StateManager{state | conns: Map.delete(state.conns, tg_user_id),
                   websocks: Map.delete(state.websocks, tg_user_id)}}
  end

  @impl true
  def handle_call({:get_app}, _from, state) do
    {:reply, state.app, state}
  end

  # client
  # -------------------------------------------------------------------------

  def get_conn(tg_user_id) do
    GenServer.call(__MODULE__, {:get_conn, tg_user_id})
  end

  def add_user(tg_user_id, conn) do
    GenServer.call(__MODULE__, {:add_user, tg_user_id, conn})
  end

  def delete_user(tg_user_id) do
    GenServer.call(__MODULE__, {:delete_user, tg_user_id})
  end

  def get_app() do
    GenServer.call(__MODULE__, {:get_app})
  end

end

