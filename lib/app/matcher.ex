# Matcher determines the type of update and allows us to write the processing of any type we need in the commands.ex

defmodule App.Matcher do
  use GenServer

  alias App.Commands
  require Logger
  import Storage

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
    {:ok, %{app: app, conn: nil, storage: Storage.init(), conns: %{}}}
  end


  @impl true
  def handle_cast(message, state) do

    if (Map.get(state.conns, message.from.id) != nil) do
      Commands.match_message(message, state)
    else
      Commands.match_message(message, state)
    end

    {:noreply, state}
  end

  # Client
  # ----------------------------------------------------------------------------

  def match(message) do
    GenServer.cast(__MODULE__, message)
  end
end
