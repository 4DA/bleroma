use Mix.Config

config :app,
  bot_name: "INSTANCE_bot",
  instance_url: "https://INSTANCE.club",
  websocket_url: "wss://INSTANCE.club/api/v1/streaming",
  register_link: "https://INSTANCE.club/registration"

config :nadia,
  token: "BOT_TOKEN"

import_config "#{Mix.env}.exs"
