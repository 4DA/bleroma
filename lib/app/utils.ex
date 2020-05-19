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
      conn = Hunter.log_in_oauth(
        StateManager.get_app(), token, base_instance)

      account = Hunter.verify_credentials(conn)
      StateManager.add_user(user_id, conn)
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

  def get_connection(user_id) do
    StateManager.get_conn(user_id)
  end

  def get_conn(%{
        message: %{
          from: user}
               }
    ) do
    get_connection(user.id)
  end

  def get_conn(%{
        inline_query: %{
          from: user}
               }) do
    get_connection(user.id)
  end

  def get_conn(%{
        callback_query: %{
          from: user}
               }) do
    get_connection(user.id)
  end
  
  bleroma_bot_id = Application.get_env(:app, :bot_name)

  defp new_status_reply_markup(status) do
    %Nadia.Model.InlineKeyboardMarkup{
      inline_keyboard: [
        [
          %{
            text: "open",
            url: "#{status.url}"
          },
          %{
            callback_data: "/del #{status.id}",
            text: "delete"
          }
        ],
      ]
    }
  end

  def make_post(
    %Nadia.Model.Update {
      message: %{reply_to_message: %{from: %{username: bleroma_bot_id}} = rmsg}
    } = update) do

    {:ok, conn} = get_conn(update)

    content = if rmsg.text do rmsg.text
              else rmsg.caption end

    caps = Regex.scan(~r/\/([a-zA-Z0-9]+)/, content)

    if Enum.empty?(caps) do
      Nadia.send_message(
        update.message.from.id, "Please reply only to bot messages with id links i.e /abcdef123")
      :error
    else
      reply_status_id = List.last(List.last(caps))
      source_status = Hunter.status(conn, reply_status_id)
      make_post(update, [visibility: "{source_status.visibility}", in_reply_to_id: reply_status_id])
    end
  end

  def get_file_from_tg(tg_user_id, file_id) do
    {:ok, nadia_file} = Nadia.get_file(file_id)
    {:ok, link} = Nadia.get_file_link(nadia_file)
    %HTTPoison.Response{body: body} = HTTPoison.get!(link)

    # TODO extend Hunter API to accept media as stream
    fname = List.last(String.split(link, "/"))
    fname = "#{tg_user_id}_#{fname}"
    File.write!(fname, body)
    fname
  end

  def make_post(update, params \\ [visibility: "private"]) do
    {:ok, conn} = get_conn(update)
    user_id = update.message.from.id

    params = params ++
    if (Enum.count(update.message.photo) > 0) do
      # TODO determine (how?) which photosize to use
      photo_idx = if Enum.count(update.message.photo) > 1 do 1 else 0 end
        
      file_path = get_file_from_tg(update.message.from.id,
        Enum.at(update.message.photo, photo_idx).file_id)

      media = Hunter.upload_media(conn, file_path)

      File.rm(file_path)

      [media_ids: [media.id]]
    else
      []
    end

    status_text = case {update.message.text, update.message.caption} do
      {nil, nil} -> ""
      {text, nil} -> text
      {nil, caption} -> caption
    end

    status = Hunter.create_status(conn, status_text, params)

    {status, new_status_reply_markup(status)}
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
  def show_status_as_anon(status_str, tg_user_id) do
    status = Poison.decode!(status_str, as: status_nested_struct())
    Logger.log(:info, "show_status = #{inspect(status)}")
    post = prepare_post(status, tg_user_id, nil)
    send_to_tg(tg_user_id, post)
  end

  def show_notification(notification, tg_user_id, conn) do
    status = Poison.decode!(notification, as: notification_nested_struct()).status

    Logger.log(:info, "show_notification = #{inspect(status)}")    
    post = prepare_post(status, tg_user_id, conn)
    send_to_tg(tg_user_id, post)
  end

  def show_update(update, tg_user_id, conn) do
    status = Poison.decode!(update, as: status_nested_struct())
    Logger.log(:info, "ignored update = #{inspect(status)}")
  end

  def post_from_template(acct, content, status_id,
    reblogs_count, favourites_count, reply_count, html \\ true, reply_to \\ nil, parent \\ nil, media \\ nil, max_content_sz \\ 3900) do

    reply_count = "x"

    ito = if html == true do "<i>" else "" end
    itc = if html == true do "</i>" else "" end

    media_str = if media do ["\n"] ++ Enum.map(media,
                    fn %Hunter.Attachment{description: desc,
                             remote_url: url} -> "<a href=\"#{url}\">#{desc}</a>\n" end)
                    else "" end

    reply_str = if reply_to do " → /" <> reply_to else "" end
    quote_str = if parent do
      if String.length(String.trim(parent)) > 80
        do
        "\n > #{ito}#{String.slice(parent, 0, 79)}#{itc}...\n"
        else
          "\n > #{ito}#{parent}#{itc}\n"
      end
    else
      "" end

    ""
    <> "#{acct}" <> "#{reply_str}" <> ":"
    <> quote_str
    <> "\n#{String.slice(content, 0, max_content_sz)}\n"
    <> "#{media_str}"
    <> "\n/#{status_id} ↶#{reply_count} 🗘#{reblogs_count} ☆#{favourites_count}"
  end

  def status_reply_markup(st, conn) do
    me = if conn do Hunter.verify_credentials(conn) else nil end

    inline_keyboard = [
      %{
        text: "open",
        url: "#{st.url}"
      }
    ]

    ++

    if me != nil do 
      if (st.account.acct == me.acct) do
        [
          %{
            callback_data: "/del #{st.id}",
            text: "Delete"
          }
        ]
      else
        repost_cmd = if st.reblogged, do: "/unrepost", else: "/repost"
        repost_text = if st.reblogged, do: "unrepost", else: "repost"

        like_cmd = if st.favourited, do: "/unlike", else: "/like"
        like_text = if st.favourited, do: "unlike", else: "like"
        [
          %{
            callback_data: "#{repost_cmd} #{st.id}",
            text: "#{repost_text}"
          },
          %{
            callback_data: "#{like_cmd} #{st.id}",
            text: "#{like_text}"
          }
        ]
      end
    else
      []
    end
    
    Logger.log(:info, "inline kbd: #{inspect(inline_keyboard)}")
    
    %Nadia.Model.InlineKeyboardMarkup{
          inline_keyboard: [
            inline_keyboard
          ]
    }
  end
  

  def prepare_post(%Hunter.Status{} = st, tg_user_id, conn) do
    {:ok, conn} = StateManager.get_conn(tg_user_id)
    status_id = st.id

    Logger.log(:info, "post = #{inspect(st)}")

    content = st.content |> HtmlSanitizeEx.Scrubber.scrub(Bleroma.Scrubber.Tg)

    reply_markup = status_reply_markup(st, conn)
    
      opts = [reply_markup: reply_markup]

      opts_parse_mode = opts ++ [{:parse_mode, "HTML"}]

      parent = if (st.in_reply_to_id) do
        HtmlSanitizeEx.strip_tags(Hunter.status(conn, st.in_reply_to_id).content)
      else
        nil
      end

      # telegram supports very small subset of html tags:
      # https://core.telegram.org/bots/api#formatting-options
      # if send is failed, send message with plain parse mode

      if (Enum.count(st.media_attachments) == 1 and hd(st.media_attachments).type == "image") do

        url = Enum.at(st.media_attachments, 0).remote_url

        content = HtmlSanitizeEx.strip_tags(st.content)

        string_to_send = post_from_template(
          st.account.acct, content, st.id, st.reblogs_count, st.favourites_count, 0, false, st.in_reply_to_id, parent, nil, 900)

        opts = opts ++ [caption: string_to_send]
        {:photo, url, opts}
        # Nadia.send_photo(tg_user_id, url, opts)

      else
        string_to_send = post_from_template(
          st.account.acct, content, st.id, st.reblogs_count, st.favourites_count, 0, false, st.in_reply_to_id, parent, st.media_attachments, 3900)

        {:message, string_to_send, opts_parse_mode}

        # case Nadia.send_message(tg_user_id, string_to_send, opts_parse_mode) do
        #   {:error, _} -> Nadia.send_message(tg_user_id, string_to_send, opts)
        #   {:ok, _} ->  {:ok}
        # end
      end
  end

  def send_to_tg(tg_user_id, {:message, string_to_send, opts_parse_mode}) do
    case Nadia.send_message(tg_user_id, string_to_send, opts_parse_mode) do
      {:error, _} -> Nadia.send_message(tg_user_id, "error")
      {:ok, _} ->  {:ok}
    end
  end

  def send_to_tg(tg_user_id, {:photo, url, opts}) do
    Nadia.send_photo(tg_user_id, url, opts)
  end

  def update_tg_message(update, status_id, conn) do
    Logger.log(:info, "edit_req = #{inspect(update)}")
    st = Hunter.status(conn, status_id)

    case prepare_post(st, update.callback_query.from.id, conn) do
      {:photo, url, opts} ->
        Nadia.edit_message_caption(update.callback_query.message.chat.id,
          update.callback_query.message.message_id, nil, opts)

      {:message, string_to_send, opts} ->
        Nadia.edit_message_text(update.callback_query.message.chat.id,
          update.callback_query.message.message_id, nil, string_to_send, opts)
    end
  end
end
