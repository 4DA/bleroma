# module for commands for logged in users
defmodule App.CommandsLI do
  use App.Router
  use App.Commander
  require Hunter
  require Bleroma.Utils

  alias App.Commands.Outside

  command ["help"] do
    oauth_link = "https://birdity.club/oauth/authorize?client_id=FpWYvIh-founF77h7u06vN_bAyYDJVzARznVO-ZjKpc&response_type=code&redirect_uri=urn%3Aietf%3Awg%3Aoauth%3A2.0%3Aoob&scope=read+write+follow"

    send_message(
      "/identify <token> :: log in using [oauth token](#{oauth_link});\n"
      <> "/logout :: log out;\n"
      <> "/help :: show this message;",
      [{:parse_mode, "markdown"}])
  end

  #ok, we are going to make a new post
  message do
    send_message("Unknown command")

    # res = Hunter.create_status(conn, update.message.text)
    # Logger.log(:info, "new status: #{inspect(res)}")
  end

end
