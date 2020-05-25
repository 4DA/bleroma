# Matcher determines the type of update and allows us to write the processing of any type we need in the commands.ex

defmodule Bleroma.Matcher do
  use GenServer

  alias Bleroma.CmdAnon
  alias Bleroma.Cmd
  import Storage
  import Bleroma.Utils
  alias Bleroma.Utils

  require Logger
  require Map

  # Server
  # ----------------------------------------------------------------------------

  def start_link do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @impl true
  def init(:ok) do
    app = Hunter.Application.load_credentials("bleroma")
    Logger.log(:info, "Loaded application #{inspect(app)}")
    {:ok, %{app: app, storage: Storage.init(), conns: %{}}}
  end

  @impl true
  def handle_cast({:masto, tg_id, %{"event" => "notification"} = message, conn}, state) do
    Logger.log(:info, "notification from maston: #{inspect(message)}")

    payload = Map.get(message, "payload")
    show_notification(payload, tg_id, conn)
    {:noreply, state}
  end

  @impl true
  def handle_cast({:masto, tg_id, %{"event" => "update", "in_reply_to_id" => nil} = message,
                   conn}, state) do
    Logger.log(:info, "update from maston: #{inspect(message)}")
    payload = Map.get(message, "payload")
    show_update(payload, tg_id, conn)
    {:noreply, state}
  end

  @impl true
  def handle_cast({:masto, _, message, _}, state) do
    Logger.log(:info, "ignoring update from maston: #{inspect(message)}")
    {:noreply, state}
  end

  @impl true
  def handle_cast(update, state) do
    Logger.log(:info, "recv msg: #{inspect(update)}")
    
    case Utils.get_conn(update) do
      {:ok, _} -> Cmd.match_message(update, state)
      :error -> CmdAnon.match_message(update, state)
    end

    {:noreply, state}
  end

  # Client
  # ----------------------------------------------------------------------------

  def match(message) do
    GenServer.cast(__MODULE__, message)
  end
end
