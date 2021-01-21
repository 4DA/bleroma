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

    # TODO, make PR to hunter to store creds in current dir
    app_creds = System.user_home() <> "/.hunter/apps/bleroma.json"

    app = if File.exists?(app_creds) do
      Logger.log(:info, "file '#{app_creds}' found")
      Hunter.Application.load_credentials("bleroma")
    else
      Logger.log(:info, "file '#{app_creds}' not found, registering new app")
	Hunter.create_app("bleroma", "urn:ietf:wg:oauth:2.0:oob", ["read", "write", "follow"],
	  nil, [save?: true, api_base_url: Application.get_env(:app, :instance_url)])
    end

    storage = Storage.init()
    all_bearers = Storage.get_all(storage)

    Logger.log(:info, "All bearers: #{inspect(all_bearers)}")    

    conns = Map.new(all_bearers, fn [tg, bearer] ->
      {tg, Utils.new_connection(tg, bearer)} end)

    Logger.log(:info, "All conns: #{inspect(conns)}")    

    opts = [strategy: :one_for_one, name: Bleroma.WSSupervisor]

    children = [
      {DynamicSupervisor, strategy: :one_for_one, name: Bleroma.DynamicSupervisor}
    ]

    Supervisor.start_link(children, strategy: :one_for_one)

    websocks = Map.new(all_bearers, fn [tg, bearer] ->
      {:ok, pid} = open_websocket(tg, Map.get(conns, tg))
      {tg, pid}
    end)

    {:ok, %StateManager{app: app, storage: storage, conns: conns, websocks: websocks}} # 
  end

  def open_websocket(tg_user_id, conn) do
      DynamicSupervisor.start_child(Bleroma.DynamicSupervisor,
      %{
        id: "Bleroma.Websocks.#{tg_user_id}",
        start: {Bleroma.Websocks, :start_link, [{tg_user_id, conn}]},
        restart: :transient
      })
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
    Storage.store_auth(state.storage, tg_user_id, conn.client.bearer_token)

    {:ok, pid} = open_websocket(tg_user_id, conn)

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

  # add update id
  def add_shown(tg_user_id, post_id) do
    Logger.log(:info, "add_shown {#{tg_user_id}, #{post_id}}")
    Cachex.incr(:shown_updates, {tg_user_id, post_id}) 
  end

  # check whether update id was shown
  def is_shown?(tg_user_id, post_id) do
    case Cachex.get(:shown_updates, {tg_user_id, post_id}) do
      {:ok, nil} -> false
      {:ok, _} -> true
    end
  end

end

