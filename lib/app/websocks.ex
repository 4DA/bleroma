defmodule Bleroma.Websocks do
  use WebSockex
  require Logger
  require Bleroma.Matcher
  require Poison

  def start_link({tg_id, conn}) do
    ws_url = Application.get_env(:app, :websocket_url)

    WebSockex.start_link("#{ws_url}?access_token=#{conn.client.bearer_token}&stream=user",
      __MODULE__, {tg_id, conn})
  end

  @spec echo(pid, String.t) :: :ok
  def echo(client, message) do
    Logger.info("Sending message: #{message}")
    WebSockex.send_frame(client, {:text, message})
  end

  def handle_connect(_conn, {tg_id, conn} = state) do
    Logger.log(:info, "Connected WS [pid=#{inspect self()}, tg_id: #{tg_id}, acc: #{conn.acct}]")
    {:ok, state}
  end

  def handle_frame({:text, msg}, {tg_id, conn} = state) do
    try do
      if (String.length(msg) > 0) do
        msg_decoded = Poison.decode!(msg)
        Logger.log(:info, "websocks: new frame for #{tg_id}/#{conn.acct}")
        Bleroma.Matcher.match({:masto, tg_id, msg_decoded, conn})
      end
    rescue err in Poison.Parse.Error ->
        Logger.error("Error decoding message from masto: #{msg}: #{inspect(err)}")
    end

    {:ok, state}
  end

  def handle_disconnect(%{reason: {:local, reason}}, state) do
    Logger.info("Local close with reason: #{inspect reason}")
    {:ok, state}
  end

  def handle_disconnect(disconnect_map, {tg_id, conn} = state) do
    Logger.log(:info,
      "Disconnected WS [pid=#{inspect self()}, tg_id: #{tg_id}, acc: #{conn.acct}]")
    super(disconnect_map, state)
  end

end
