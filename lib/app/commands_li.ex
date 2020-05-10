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


  command ["help"] do
    oauth_link = "https://birdity.club/oauth/authorize?client_id=FpWYvIh-founF77h7u06vN_bAyYDJVzARznVO-ZjKpc&response_type=code&redirect_uri=urn%3Aietf%3Awg%3Aoauth%3A2.0%3Aoob&scope=read+write+follow"

    send_message(
      "/identify <token> :: log in using [oauth token](#{oauth_link});\n"
      <> "/logout :: log out;\n"
      <> "/help :: show this message;",
      [{:parse_mode, "markdown"}])
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

  # The `message` macro must come at the end since it matches anything.
  # You may use it as a fallback.
  message do
    send_message("Unknown command")
  end

end
