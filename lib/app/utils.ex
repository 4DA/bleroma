defmodule Bleroma.Utils do
  require Logger
  require Nadia
  
  def login_user(user_id, username, token, state) do
    base_instance = Application.get_env(:app, :instance_url)
    
    try do
      conn = Hunter.log_in_oauth(state.app, token, base_instance)
      account = Hunter.verify_credentials(conn)
      Storage.store_auth(state.storage, user_id, conn.bearer_token)
      Map.put(state.conns, user_id, conn)
      Logger.log(:info, "Auth OK for tg_user_id=#{user_id} name=#{username} conn=#{inspect(conn)}")
      {:ok, conn, account}
    rescue
      err in Hunter.Error -> {:error, "#{inspect(err)}"}
    end
  end

  def get_connection(user_id, state) do
    base_instance = Application.get_env(:app, :instance_url)

    # try to get conn from memory
    conn_mem = Map.get(state.conns, user_id)

    if conn_mem == nil do
      # try to load user connection to instance from storage
      bearer = case Storage.get_auth(state.storage, user_id) do
               {:ok, result} -> result
               {:error} -> nil
               end

      try do
        nc = Hunter.new([base_url: base_instance, bearer_token: bearer])
        account = Hunter.verify_credentials(nc)
        state = put_in(state[:conns][user_id], nc)
        {nc, state}
      rescue
        err in Hunter.Error ->
          Logger.log(:error, "verify_creds error for tg_user_id=#{user_id}: #{inspect(err)}"); {nil, state}
      end
    else
      {conn_mem, state}
    end
  end

  def get_conn(%{
        message: %{
          from: user}
               },
    state) do
    get_connection(user.id, state)
  end

  def get_conn(%{
        inline_query: %{
          from: user}
               },
    state) do
    get_connection(user.id, state)
  end

  def get_conn(%{
        callback_query: %{
          from: user}
               },
    state) do
    get_connection(user.id, state)
  end
  
  bleroma_bot_id = Application.get_env(:app, :bot_name)

  def make_post(
    %Nadia.Model.Update{message: %{reply_to_message: %{from: %{username: bleroma_bot_id}} = rmsg}},
    state
  ) do

    Logger.log(:info, "catched reply to msg #{inspect(rmsg)}")
    # status = Hunter.create_status(conn, message.message.text, [visibility: "private", in_reply_to_id: id])
    # Logger.log(:info, "new reply: #{inspect(status)}")

    # reply_markup =  %Nadia.Model.InlineKeyboardMarkup{
    #       inline_keyboard: [
    #         [
    #           %{
    #             text: "Open",
    #             url: "#{status.url}"
    #           },
    #           %{
    #             callback_data: "/del #{status.id}",
    #             text: "Delete"
    #           }
    #         ],
    #       ]
    #     }

    # params = [visibility: "private", reply_markup: reply_markup]

    # Nadia.send_message(user_id, "Reply posted: #{status.url}",
    #    [visibility: "private", reply_markup: reply_markup])
  end
  def make_post(update, state) do
    {conn, state} = get_conn(update, state)
    user_id = update.message.from.id

    status = Hunter.create_status(conn, update.message.text, [visibility: "private"])
    Logger.log(:info, "new status: #{inspect(status)}")

    reply_markup =  %Nadia.Model.InlineKeyboardMarkup{
          inline_keyboard: [
            [
              %{
                text: "Open",
                url: "#{status.url}"
              },
              %{
                callback_data: "/del #{status.id}",
                text: "Delete"
              }
            ],
          ]
        }

    params = [visibility: "private", reply_markup: reply_markup]

    Nadia.send_message(user_id, "Status posted: /#{status.id}",
       [visibility: "private", reply_markup: reply_markup])
  end

  def show_post(status_id, tg_user_id, state) do
    conn = Map.get(state.conns, tg_user_id)
    try do
      st = Hunter.status(conn, status_id)

      string_to_send = ""
      <> "@#{st.account.acct}\n"
      <> "#{st.content}\n"
      <> "/#{status_id} 🗘#{st.reblogs_count} ☆#{st.favourites_count}"

    reply_markup =  %Nadia.Model.InlineKeyboardMarkup{
          inline_keyboard: [
            [
              %{
                text: "Open",
                url: "#{st.url}"
              }
            ],
          ]
        }

      opts = [reply_markup: reply_markup]

      opts_parse_mode = opts ++
      if (st.content =~ "<a" or st.content =~ "<b>" or st.content =~ "<i>" or
        st.content =~ "<u>" or st.content =~ "<code>" or st.content =~ "<pre>") do
        [{:parse_mode, "HTML"}]
      else
        []
      end

      # telegram supports very little subset of html tags:
      # https://core.telegram.org/bots/api#formatting-options
      # if send is failed, send message with plain parse mode

      case Nadia.send_message(tg_user_id, string_to_send, opts_parse_mode) do
        {:error, _} -> Nadia.send_message(tg_user_id, string_to_send, opts)
        {:ok, _} ->  {:ok}
      end

    rescue err in Hunter.Error -> Logger.log(:error, "Error fetching status #{inspect(err)}");
                                  {:error, err}    
    end
  end
  
end
