defmodule Bleroma.CmdAnon do
  use Bleroma.Router
  use Bleroma.Commander
  require Hunter
  require Bleroma.Utils
  alias Bleroma.Utils

  # You can create commands in the format `/command` by
  # using the macro `command "command"`.
  command "start" do
    Logger.log(:info, "Command /start received")
    send_message "Hello, " <> update.message.from.username
  end


  def getHelpStringAnon() do
    # @TODO generate this link via api
    register_link = Application.get_env(:app, :register_link)
    oauth_link = "https://birdity.club/oauth/authorize?client_id=FpWYvIh-founF77h7u06vN_bAyYDJVzARznVO-ZjKpc&response_type=code&redirect_uri=urn%3Aietf%3Awg%3Aoauth%3A2.0%3Aoob&scope=read+write+follow"

    ""
    <> "Visit [this link](#{oauth_link}) to authenticate, and send me code via /identify\n"
    <> "If you don't have account, register [here](#{register_link})"
    <> "\n/identify <token> - login as user using oauth token\n"
  end

  command ["help"] do
    send_message(
      getHelpStringAnon(),
      [{:parse_mode, "markdown"}])
  end

  command ["identify"] do
    [_command | args] = String.split(update.message.text, " ")

    # send_message("Your arguments were: " <> Enum.join(args, " "))

    token = Enum.at(args, 0)
    user_id = update.message.from.id
    username = update.message.from.username

    # send_message("User id: " <> user_id <> " token: " <> token)
    Logger.log(:info, "/identify from [id=#{user_id} name=#{username} oauth=#{token}]")

    # verify creds
    base_instance = Application.get_env(:app, :instance_url)

    conn = Bleroma.Utils.login_user(user_id, username, token, state)
    case conn do
      {:ok, _, account} -> send_message("You have been authenticated as #{account.acct}")
      {:error, reason} -> send_message("Authentication error: #{inspect(reason)}")
    end
  end

  command ["hello", "hi"] do
    # Logger module injected from Bleroma.Commander
    Logger.log(:info, "Command /hello or /hi")

    # You can use almost any function from the Nadia core without
    # having to specify the current chat ID as you can see below.
    # For example, `Nadia.send_message/3` takes as first argument
    # the ID of the chat you want to send this message. Using the
    # macro `send_message/2` defined at Bleroma.Commander, it is
    # injected the proper ID at the function. Go take a look.
    #
    # See also: https://hexdocs.pm/nadia/Nadia.html
    send_message("Hello World!")
  end

  # Fallbacks
  # ----------------------------------------------------------------------------

  # Rescues any unmatched callback query.
  callback_query do
    Logger.log(:warn, "Did not match any callback query")

    answer_callback_query(text: "Sorry, but there is no JoJo better than Joseph.")
  end

  # Rescues any unmatched inline query.
  inline_query do
    Logger.log(:warn, "Did not match any inline query")
  end

  # The `message` macro must come at the end since it matches anything.
  # You may use it as a fallback.
  message do
    if String.match?(update.message.text, ~r/^\/[a-zA-Z0-9]+$/) do
      # {:ok, conn} = StateManager.get_conn(update.message.from.id)
      tg_user_id = update.message.from.id

      status_id = Enum.at(String.split(update.message.text, "/"), 1)
      case Bleroma.Helpers.status_dump_str("https://birdity.club", status_id) do
        nil -> Nadia.send_message(tg_user_id, "Status not found")
        status -> Utils.show_status_as_anon(status, update.message.from.id)
      end
    else
      send_message(getHelpStringAnon())
    end
  end
end