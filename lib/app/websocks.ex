defmodule Bleroma.Websocks do
  use WebSockex
  require Logger

  def start_link(conn) do
    ws_url = Application.get_env(:app, :websocket_url)
    access_token = conn.bearer_token
    WebSockex.start_link("#{ws_url}?access_token=#{conn.bearer_token}&stream=user", __MODULE__, :fake_state,
      ssl_options: [
        ciphers: :ssl.cipher_suites() ++ [{:rsa, :aes_128_cbc, :sha}]
      ]
    )
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

  def handle_frame({:text, "Can you please reply yourself?" = msg}, :fake_state) do
    Logger.info("Received Message: #{msg}")
    msg = "Sure can!"
    Logger.info("Sending message: #{msg}")
    {:reply, {:text, msg}, :fake_state}
  end
  def handle_frame({:text, "Close the things!" = msg}, :fake_state) do
    Logger.info("Received Message: #{msg}")
    {:close, :fake_state}
  end
  def handle_frame({:text, msg}, :fake_state) do
    Logger.info("Received Message: #{msg}")
    {:ok, :fake_state}
  end

  def handle_disconnect(%{reason: {:local, reason}}, state) do
    Logger.info("Local close with reason: #{inspect reason}")
    {:ok, state}
  end
  def handle_disconnect(disconnect_map, state) do
    super(disconnect_map, state)
  end
end
