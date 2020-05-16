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
        [{telegram_id, auth}] -> {:ok, auth}
        [] -> {:error}
      end
  end

  # def get_all(table) do

  # end

  def bearer_filter(tg_id, bearer) do
    bearer
  end

  def get_all(table) do
    :dets.match(table,  {:"$1", :"$2"})
  end

  # defp key_stream(table_name) do
  #   Stream.resource(
  #     fn -> :ets.first(table_name) end,
  #     fn :"$end_of_table" -> {:halt, nil}
  #       previous_key -> {[previous_key], :ets.next(table_name, previous_key)} end,
  #     fn _ -> :ok end)
  # end
  
end
