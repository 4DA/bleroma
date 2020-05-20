use Mix.Config

config :app,
  bot_name: "INSTANCE_bot",
  instance_url: "https://INSTANCE.club",
  websocket_url: "wss://INSTANCE.club/api/v1/streaming",
  instance_client_id: "INSTANCE_CLIENT_ID",
  instance_client_secret: "INSTANCE_CLIENT_SECRENT",
  register_link: "https://INSTANCE.club/registration"

config :nadia,
  token: "BOT_TOKEN"

import_config "#{Mix.env}.exs"
