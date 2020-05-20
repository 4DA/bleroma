# Matcher determines the type of update and allows us to write the processing of any type we need in the commands.ex

defmodule Bleroma.Matcher do
  use GenServer

  alias Bleroma.Commands
  alias Bleroma.CommandsLI
  import Storage
  import Bleroma.Utils
  alias Bleroma.Utils

  require Logger
  require Map


  # Server
  # ----------------------------------------------------------------------------
  # def send_auth_help(user_id) do
  
  #   oauth_link = "https://birdity.club/oauth/authorize?client_id=FpWYvIh-founF77h7u06vN_bAyYDJVzARznVO-ZjKpc&response_type=code&redirect_uri=urn%3Aietf%3Awg%3Aoauth%3A2.0%3Aoob&scope=read+write+follow"

  #   Nadia.send_message(
  #     user,
  #     "Visit [this link](#{oauth_link}) authenticate, and send me the code\n",
  #     [{:parse_mode, "markdown"}])
  # end

  def start_link do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @impl true
  def init(:ok) do
    app = Hunter.Application.load_credentials("bleroma")
    Logger.log(:info, "Loaded application #{inspect(app)}")
    {:ok, %{app: app, storage: Storage.init(), conns: %{}}}
  end

  # @impl true
  # def handle_cast(:hello, state) do
  #   Logger.log(:info, "hello")
  #   {:noreply, state}
  # end

  @impl true
  def handle_cast({:masto, tg_id, %{"event" => "notification"} = message, conn} = arg, state) do
    Logger.log(:info, "notification from maston: #{inspect(message)}")

    payload = Map.get(message, "payload")
    show_notification(payload, tg_id, conn)
    {:noreply, state}
  end

  @impl true
  def handle_cast({:masto, tg_id, %{"event" => "update"} = message, conn} = arg, state) do
    Logger.log(:info, "update from maston: #{inspect(message)}")
    payload = Map.get(message, "payload")
    show_update(payload, tg_id, conn)
    {:noreply, state}
  end

  @impl true
  def handle_cast({:masto, tg_id, message, conn} = arg, state) do
    Logger.log(:info, "ignoring update from maston: #{inspect(message)}")
    {:noreply, state}
  end

  @impl true
  def handle_cast(update, state) do
    Logger.log(:info, "recv msg: #{inspect(update)}")
    
    case Utils.get_conn(update) do
      {:ok, conn} -> CommandsLI.match_message(update, state)
      :error -> state = Commands.match_message(update, state)
    end

    {:noreply, state}
  end

  # Client
  # ----------------------------------------------------------------------------

  def match(message) do
    GenServer.cast(__MODULE__, message)
  end
end
