## Features
- Sending messages
- Sending photos
- Receiving notifications from user subscriptions

## Configuration
Create bleroma.json
```
iex -S mix

```

```
config :app,
  bot_name: "XXX_bot",
  instance_url: "https://XXX",
  websocket_url: "wss://XXX/api/v1/streaming",
  instance_client_id: "XXX",
  instance_client_secret: "XXX",
  register_link: "XXX"

config :nadia,
  token: "XXX" #<- bot api token
```

## See also
[Used as reference](https://github.com/lubien/elixir-telegram-bot-boilerplate)

## License

[MIT](LICENSE.md)
