defmodule StateManager do
  use GenServer
  require Logger
  require Bleroma.Utils
  alias Bleroma.Utils

  defstruct app: nil, storage: nil, conns: %{}

  # server
  @impl true
  def start_link(arg) do
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

    conns = Enum.map(all_bearers, fn [tg, bearer] ->
      Utils.new_connection(tg, bearer) end)

    conns = Map.new(all_bearers, fn [tg, bearer] ->
      {tg, Utils.new_connection(tg, bearer)} end)

    Logger.log(:info, "All conns: #{inspect(conns)}")    

    {:ok, %StateManager{app: app, storage: storage, conns: conns}} # 
  end

  @impl true
  def handle_call({:get_conn, tg_user_id}, _from, state) do
    case Map.get(state.conns, tg_user_id, nil) do
      nil -> {:reply, :error, state}
      value -> {:reply, {:ok, value}, state}
    end
  end

  # client
  def get_conn(tg_user_id) do
    GenServer.call(__MODULE__, {:get_conn, tg_user_id})
  end

  def add_conn(tg_user_id, bearer_token) do
    GenServer.cast(__MODULE__, {:add_conn, tg_user_id, bearer_token})
  end

end

