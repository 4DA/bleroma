# module for commands for logged in users
defmodule App.CommandsLI do
  use App.Router
  use App.Commander
  require Hunter
  require Bleroma.Utils
  alias Bleroma.Utils

  alias App.Commands.Outside

  command ["notifications"] do
    # try do
      conn = Map.get(state.conns, update.message.from.id)
      Logger.log(:info, "notconn: #{inspect(conn)}")
      status = Hunter.notifications(conn)

      Logger.log(:info, "notifications: #{inspect(status)}")

      send_message("Your notifications:")
    # rescue
      # err in Hunter.Error -> Log.log(:error, "hunter error: #{err}")
    # end
  end

  command ["del"] do
    conn = Map.get(state.conns, update.message.from.id)
    [_command | id] = String.split(update.message.text, " ")
    res = Hunter.destroy_status(conn, id)
    Logger.log(:init, "Deleted: #{id}")
    send_message("Deleted: #{id}")
  end

  callback_query_command "del" do
    conn = Map.get(state.conns, update.callback_query.from.id)
    [_command | id] = String.split(update.callback_query.data, " ")

    res = try do
      Hunter.destroy_status(conn, id)
      answer_callback_query(text: "Done")
    rescue
      err in Hunter.Error -> {:error, "#{inspect(err)}"};
                              Logger.log(:error, "Delete error: #{inspect(err)}");
                              answer_callback_query(text: "Error")
    end
  end

  command ["help"] do
    oauth_link = "https://birdity.club/oauth/authorize?client_id=FpWYvIh-founF77h7u06vN_bAyYDJVzARznVO-ZjKpc&response_type=code&redirect_uri=urn%3Aietf%3Awg%3Aoauth%3A2.0%3Aoob&scope=read+write+follow"

    send_message(
      "/identify <token> :: log in using [oauth token](#{oauth_link});\n"
      <> "/visibility :: get status visibility;"
      <> "/visibility <value> :: set status visibility [public, unlisted, followers, direct];"
      <> "/logout :: log out;\n"
      <> "/help :: show this message;",
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
      {:error, reason} -> send_message("Authentication error")
    end
  end


  callback_query_command "choose" do
    Logger.log(:info, "Callback Query Command /choose")

    case update.callback_query.data do
      "/choose joseph" ->
        answer_callback_query(text: "Indeed you have good taste.")

      "/choose joseph-of-course" ->
        answer_callback_query(text: "I can't agree more.")
    end
  end


  # Fallbacks

  callback_query do
    Logger.log(:warn, "Did not match any callback query")

    answer_callback_query(text: "Sorry, but there is no JoJo better than Joseph.")
  end

  # Rescues any unmatched inline query.
  inline_query do
    Logger.log(:warn, "Did not match any inline query")

    :ok =
      answer_inline_query([
        %InlineQueryResult.Article{
          id: "1",
          title: "Darude-Sandstorm Non non Biyori Renge Miyauchi Cover 1 Hour",
          thumb_url: "https://img.youtube.com/vi/yZi89iQ11eM/3.jpg",
          description: "Did you mean Darude Sandstorm?",
          input_message_content: %{
            message_text: "https://www.youtube.com/watch?v=yZi89iQ11eM"
          }
        }
      ])
  end

  # Message without commands, time for a new status
  message do
    if String.match?(update.message.text, ~r/^\/[a-zA-Z0-9]+$/) do
      Utils.show_post(Enum.at(String.split(update.message.text, "/"), 1), update.message.from.id, state)
    else
      Utils.make_post(update, state)
    end
  end

end
