import Config

config :app,
  bot_name: "birditytest_bot",
  instance_url: "https://birdity.club",
  websocket_url: "wss://birdity.club/api/v1/streaming",
  register_link: "https://INSTANCE.club/registration"

config :nadia,
  # token: "1182983412:AAHUMDIMPMSXW-AoWoXzQfupqg_hk73GOBw"
  token: "888223960:AAF7ZNfHz_O1qYWx_Kh4AnuG4-Kouxb96I4"

config :logger,
  truncate: 65535

import_config "#{Mix.env}.exs"
