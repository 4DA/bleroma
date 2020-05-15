defmodule Bleroma.Utils do
  require Logger
  require Nadia
  require Bleroma.Scrubber.Tg
  require Bleroma.Helpers

  require Hunter
  alias Hunter.{Api.Request, Config}
  
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

  def new_connection(user_id, bearer) do
    base_instance = Application.get_env(:app, :instance_url)
      try do
        nc = Hunter.new([base_url: base_instance, bearer_token: bearer])
        account = Hunter.verify_credentials(nc)
        nc
      rescue
        err in Hunter.Error ->
          Logger.log(:error, "new_connection: verify_creds error for tg_user_id=#{user_id}: #{inspect(err)}");
          nil
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
      if bearer == nil do
        {nil, state}
      else
        try do
          nc = Hunter.new([base_url: base_instance, bearer_token: bearer])
          account = Hunter.verify_credentials(nc)
          state = put_in(state[:conns][user_id], nc)
          {nc, state}
        rescue
          err in Hunter.Error ->
            Logger.log(:error, "get_connection: verify_creds error for tg_user_id=#{user_id}: #{inspect(err)}"); {nil, state}
        end
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
    %Nadia.Model.Update{message: %{reply_to_message: %{from: %{username: bleroma_bot_id}} = rmsg}} = update,
    state
  ) do

    {conn, state} = get_conn(update, state)

    caps = Regex.scan(~r/\/([a-zA-Z0-9]+)/, rmsg.text)

    if Enum.empty?(caps) do
      Nadia.send_message(
        update.message.from.id, "Please reply only to bot messages with id links i.e /abcdef123")
    else
      reply_status_id = List.last(List.last(caps))

      Logger.log(:info, "catched reply to msg #{inspect(rmsg)} stat id: #{reply_status_id}")

      status = Hunter.create_status(conn, update.message.text,
        [visibility: "private", in_reply_to_id: reply_status_id])

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

      Nadia.send_message(update.message.from.id, "Reply posted: /#{status.id}",
        [reply_markup: reply_markup])
    end
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
       [reply_markup: reply_markup])
  end

  defp status_nested_struct do
    %Hunter.Status{
      account: %Hunter.Account{},
      reblog: %Hunter.Status{},
      media_attachments: [%Hunter.Attachment{}],
      mentions: [%Hunter.Mention{}],
      tags: [%Hunter.Tag{}],
      application: %Hunter.Application{}
    }
  end

  defp notification_nested_struct do
    %Hunter.Notification{
      account: %Hunter.Account{},
      status: %Hunter.Status{
        account: %Hunter.Account{},
        reblog: %Hunter.Status{},
        media_attachments: [%Hunter.Attachment{}],
        mentions: [%Hunter.Mention{}],
        tags: [%Hunter.Tag{}],
        application: %Hunter.Application{}
      }
    }
  end

  # @todo find out how to match string type
  def show_status_str(status_str, tg_user_id) do
    status = Poison.decode!(status_str, as: status_nested_struct())
    Logger.log(:info, "show_status = #{inspect(status)}")
    show_post(status, tg_user_id)
  end

  def show_notification(notification, tg_user_id, conn) do
    status = Poison.decode!(notification, as: notification_nested_struct()).status

    Logger.log(:info, "show_notification = #{inspect(status)}")    
    show_post(status, tg_user_id)
  end

  def show_post(%Hunter.Status{} = st, tg_user_id) do
      status_id = st.id

      content = st.content |> HtmlSanitizeEx.Scrubber.scrub(Bleroma.Scrubber.Tg)

    in_reply_to_id = if st.in_reply_to_id do
      " -> /" <> st.in_reply_to_id
    else
      ""
    end

      string_to_send = ""
      <> "@#{st.account.acct}" <> "#{in_reply_to_id}"
      <> "\n#{content}\n"
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
      if (content =~ "<a" or content =~ "<b>" or content =~ "<i>" or
        content =~ "<u>" or content =~ "<code>" or content =~ "<pre>") do
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
  end
  
end
