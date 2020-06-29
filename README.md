## Features
- Sending messages
- Sending photos/audio/files
- Receiving notifications from subscriptions
- Receiving new posts from subscriptions

## Configuration
1. Install [Elixir](https://elixir-lang.org/install.html) with Erlang OTP 22 (23 is not yet tested);
2. Set instance and telegram parameters to `config/config.exs`:
```
config :app,
  bot_name: "XXX_bot",
  instance_url: "https://XXX",
  websocket_url: "wss://XXX/api/v1/streaming",
  register_link: "XXX"

config :nadia,
  token: "XXX" #<- bot api token
```

Go to project root and type:
```
mix deps.get
```

## Running
Go to project root and type:
```
mix
```

## See also
[Used as reference](https://github.com/lubien/elixir-telegram-bot-boilerplate)

## License

[MIT](LICENSE.md)
