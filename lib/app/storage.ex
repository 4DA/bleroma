defmodule Storage do
  
  def init() do
    {:ok, table} = :dets.open_file(:bleroma_users, [type: :set])
    table
  end

  def store_auth(table, telegram_id, bearer) do
    :dets.insert(table, {telegram_id, bearer})
  end

  def delete_auth(table, telegram_id) do
    :dets.delete(table, telegram_id)
  end

  def get_auth(table, telegram_id) do
      case :dets.lookup(table, telegram_id) do
        [{_, auth}] -> {:ok, auth}
        [] -> {:error}
      end
  end

  def get_all(table) do
    :dets.match(table,  {:"$1", :"$2"})
  end
  
end
