defmodule Storage do
  
  def init() do
    {:ok, table} = :dets.open_file(:bleroma_users, [type: :set])
    table
  end

  def store_auth(table, telegram_id, bearer) do
    :dets.insert(table, {telegram_id, bearer})
  end

  def get_auth(table, telegram_id) do
      case :dets.lookup(table, telegram_id) do
        [{telegram_id, auth}] -> {:ok, auth}
        [] -> {:error}
      end
  end
  
end
