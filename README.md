## Features
- Sending messages
- Sending photos/audio/files
- Receiving notifications from subscriptions
- Receiving new posts from subscriptions

## Configuration
Set instance and telegram parameters to `config/config.exs`:
```
config :app,
  bot_name: "XXX_bot",
  instance_url: "https://XXX",
  websocket_url: "wss://XXX/api/v1/streaming",
  register_link: "XXX"

config :nadia,
  token: "XXX" #<- bot api token
```

## See also
[Used as reference](https://github.com/lubien/elixir-telegram-bot-boilerplate)

## License

[MIT](LICENSE.md)
