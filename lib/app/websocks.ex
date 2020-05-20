defmodule Bleroma.Websocks do
  use WebSockex
  require Logger
  require Bleroma.Matcher
  require Poison

  def start_link({tg_id, conn, matcher} = state) do
    ws_url = Application.get_env(:app, :websocket_url)
    access_token = conn.bearer_token

    WebSockex.start_link("#{ws_url}?access_token=#{conn.bearer_token}&stream=user",
      __MODULE__, {tg_id, conn, matcher}, ssl_options: [
        ciphers: :ssl.cipher_suites() ++ [{:rsa, :aes_128_cbc, :sha}]
      ])

    Logger.log(:info, "Started WS [tg_id: #{tg_id}, bearer: #{access_token}]")
  end

  @spec echo(pid, String.t) :: :ok
  def echo(client, message) do
    Logger.info("Sending message: #{message}")
    WebSockex.send_frame(client, {:text, message})
  end

  def handle_connect(_conn, state) do
    Logger.info("Connected!")
    {:ok, state}
  end

  # def handle_frame({:text, "Can you please reply yourself?" = msg}, state) do
  #   Logger.info("Received Message: #{msg}")
  #   msg = "Sure can!"
  #   Logger.info("Sending message: #{msg}")
  #   {:reply, {:text, msg}, state}
  # end
  # def handle_frame({:text, "Close the things!" = msg}, state) do
  #   Logger.info("Received Message: #{msg}")
  #   {:close, state}
  # end

  def handle_frame({:text, msg}, {tg_id, conn, matcher} = state) do
    try do
      if (String.length(msg) > 0) do
        Bleroma.Matcher.match({:masto, tg_id, Poison.decode!(msg), conn})
      end
    rescue err in Poison.Parse.Error -> Logger.error("Error decoding message from masto: #{msg}")
    end

    {:ok, state}
  end

  def handle_disconnect(%{reason: {:local, reason}}, state) do
    Logger.info("Local close with reason: #{inspect reason}")
    {:ok, state}
  end
  def handle_disconnect(disconnect_map, state) do
    super(disconnect_map, state)
  end
end
