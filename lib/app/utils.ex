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
      Logger.log(:info, "Auth OK for user id=#{user_id} name=#{username} conn=#{inspect(conn)}")
      {:ok, conn, account}
    rescue
      err in Hunter.Error -> {:error, "#{inspect(err)}"}
    end
  end

  def get_connection(user_id, state) do
    base_instance = Application.get_env(:app, :instance_url)

    # try to get conn from memory
    conn_mem = Map.get(state.conns, user_id)

    conn_err = nil

    if conn_mem == nil do
      # try to load user connection to instance from storage
      bearer = case Storage.get_auth(state.storage, user_id) do
               {:ok, result} -> result
               {:error} -> nil
               end

      Logger.log(:info, "Bearer: #{inspect(bearer)}")

      # make a new connection
      conn_new = nil
      try do
        Hunter.new([base_url: base_instance, bearer_token: bearer])
      rescue
        err in Hunter.Error -> nil
      end
    else
      conn_mem
    end
  end

  def make_post(user_id, state, conn, message) do
    Nadia.send_message(user_id, "yay", [{:parse_mode, "markdown"}])
  end

end
