# module for commands for logged in users
defmodule Bleroma.Cmd do
  require Hunter
  require Bleroma.Utils
  alias Bleroma.Utils

  use Bleroma.Router
  use Bleroma.Commander

  # command ["notifications"] do
  #   # try do
  #     {:ok, conn} = StateManager.get_conn(update.message.from.id)
  #     Logger.log(:info, "notconn: #{inspect(conn)}")
  #     status = Hunter.notifications(conn)

  #     Logger.log(:info, "notifications: #{inspect(status)}")

  #     send_message("Your notifications:")
  #   # rescue
  #     # err in Hunter.Error -> Log.log(:error, "hunter error: #{err}")
  #   # end
  # end

  callback_query_command "userinfo" do
    {:ok, conn} = StateManager.get_conn(update.callback_query.from.id)
    [_command | pleroma_id] = String.split(update.callback_query.data, " ")

    try do
      {text, markup} = Utils.prepare_account_card(pleroma_id, update.callback_query.from.id, conn)
      Nadia.send_message(update.callback_query.from.id, text,
        [reply_markup: markup, parse_mode: "HTML"])

      answer_callback_query(text: "ok")

    rescue
      err in Hunter.Error ->  Logger.log(:error, "Error: #{inspect(err)}");
                              answer_callback_query(text: "#{inspect(err.reason)}")
    end
  end

  callback_query_command "follow" do
    {:ok, conn} = StateManager.get_conn(update.callback_query.from.id)
    [_command | id] = String.split(update.callback_query.data, " ")

    try do
      Hunter.follow(conn, id)
      answer_callback_query(text: "Done")

      {text, markup} = Utils.prepare_account_card(id, update.callback_query.from.id, conn)

      Nadia.edit_message_text(update.callback_query.message.chat.id,
        update.callback_query.message.message_id, nil, text,
        [reply_markup: markup, parse_mode: "HTML"])
    rescue
      err in Hunter.Error -> {:error, "#{inspect(err)}"};
                              Logger.log(:error, "Error: #{inspect(err)}");
                              answer_callback_query(text: "#{inspect(err.reason)}")
    end
  end

  callback_query_command "unfollow" do
    {:ok, conn} = StateManager.get_conn(update.callback_query.from.id)
    [_command | id] = String.split(update.callback_query.data, " ")

    try do
      Hunter.unfollow(conn, id)
      answer_callback_query(text: "Done")

      {text, markup} = Utils.prepare_account_card(id, update.callback_query.from.id, conn)

      Nadia.edit_message_text(update.callback_query.message.chat.id,
        update.callback_query.message.message_id, nil, text,
        [reply_markup: markup, parse_mode: "HTML"])

    rescue
      err in Hunter.Error -> {:error, "#{inspect(err)}"};
                              Logger.log(:error, "Error: #{inspect(err)}");
                              answer_callback_query(text: "#{inspect(err.reason)}")
    end
  end


  callback_query_command "del" do
    {:ok, conn} = StateManager.get_conn(update.callback_query.from.id)
    [_command | id] = String.split(update.callback_query.data, " ")

    try do
      Hunter.destroy_status(conn, id)
      answer_callback_query(text: "Done")
    rescue
      err in Hunter.Error -> {:error, "#{inspect(err)}"};
                              Logger.log(:error, "Delete error: #{inspect(err)}");
                              answer_callback_query(text: "#{inspect(err.reason)}")
    end
  end

  callback_query_command "repost" do
    {:ok, conn} = StateManager.get_conn(update.callback_query.from.id)
    [_command | st_id] = String.split(update.callback_query.data, " ")

      try do
        Hunter.reblog(conn, st_id)
        answer_callback_query(text: "Reposted")
        Utils.update_tg_message(update, st_id, conn)
      rescue
        err in Hunter.Error -> {:error, "#{inspect(err)}"};
         Logger.log(:error, "Repost error: #{inspect(err)}");
         answer_callback_query(text: "#{inspect(err.reason)}")
      end
  end

  callback_query_command "unrepost" do
    {:ok, conn} = StateManager.get_conn(update.callback_query.from.id)
    [_command | st_id] = String.split(update.callback_query.data, " ")

      try do
        Hunter.unreblog(conn, st_id)
        answer_callback_query(text: "Unreposted")
        Utils.update_tg_message(update, st_id, conn)

      rescue
        err in Hunter.Error -> {:error, "#{inspect(err)}"};
         Logger.log(:error, "Unrepost error: #{inspect(err)}");
         answer_callback_query(text: "#{inspect(err.reason)}")
      end
  end

  callback_query_command "like" do
    {:ok, conn} = StateManager.get_conn(update.callback_query.from.id)
    [_command | st_id] = String.split(update.callback_query.data, " ")

      try do
        Hunter.favourite(conn, st_id)
        answer_callback_query(text: "Liked")

        Utils.update_tg_message(update, st_id, conn)
          
      rescue
        err in Hunter.Error -> {:error, "#{inspect(err)}"};
         Logger.log(:error, "Delete error: #{inspect(err)}");
         answer_callback_query(text: "#{inspect(err.reason)}")
      end
  end

  callback_query_command "unlike" do
    {:ok, conn} = StateManager.get_conn(update.callback_query.from.id)
    [_command | st_id] = String.split(update.callback_query.data, " ")

      try do
        Hunter.unfavourite(conn, st_id)
        answer_callback_query(text: "Unliked")

        Utils.update_tg_message(update, st_id, conn)

      rescue
        err in Hunter.Error -> {:error, "#{inspect(err)}"};
         Logger.log(:error, "Delete error: #{inspect(err)}");
         answer_callback_query(text: "Error #{inspect(err.reason)}")
      end
  end

  command ["help"] do
    send_message(
      ""
      <> "/logout - log out\n"
      <> "/help - show this message",
      [{:parse_mode, "markdown"}])
  end

  command "logout" do
    send_message("Done")
    StateManager.delete_user(update.message.from.id)
  end

  # Fallbacks
  # ----------------------------------------------------------------------------

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

  message do
    # command with id
    if update.message.text != nil and String.match?(update.message.text, ~r/^\/[a-zA-Z0-9]+$/) do
      {:ok, conn} = StateManager.get_conn(update.message.from.id)
      tg_user_id = update.message.from.id

      try do
        status_id = Enum.at(String.split(update.message.text, "/"), 1)
        status = Hunter.status(conn, status_id)
        post = Utils.prepare_post(status, tg_user_id, conn)
        Utils.send_to_tg(tg_user_id, post)
      rescue err in Hunter.Error ->
          Nadia.send_message(tg_user_id, "Error fetching status #{err.reason}")
      end

    # try to make post
    else
      try do
        case Utils.make_post(update) do
          {status, reply_markup} ->
            Nadia.send_message(update.message.from.id, "Posted: /#{status.id}",
              [reply_markup: reply_markup])
          {:error} -> :error
        end
      rescue err in Hunter.Error ->
          Logger.log(:error, "Error posting status #{inspect(err)}");
          Nadia.send_message(update.message.from.id, "Error posting status: #{err.reason}")
      catch
        :exit, _ -> Logger.log(:error, "Exit")
      end
    end
  end
end
