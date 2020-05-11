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
  

  def make_post(user_id, state, conn, message) do


    status = Hunter.create_status(conn, message.message.text, [visibility: "private"])
    Logger.log(:info, "new status: #{inspect(status)}")

    reply_markup =  %Nadia.Model.InlineKeyboardMarkup{
          inline_keyboard: [
            [
              %{
                callback_data: "/show #{status.url}",
                text: "Open"
              },
              %{
                callback_data: "/del #{status.url}",
                text: "Delete"
              }
            ],


          ]
        }

    params = [visibility: "private", reply_markup: reply_markup]

    Nadia.send_message(user_id, "Status posted: #{status.url}",
       [visibility: "private", reply_markup: reply_markup])

    # Nadia.send_message(user_id,
    #   "Will be posted: `#{message.message.text}` | params: `#{inspect(params)}`",
    #   reply_markup: reply_markup
    # )   

  end

end
