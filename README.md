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

## Using bot
You need to paste ouath token from your instance. Send `/help` to bot to get oauth link.
After oauth validation on instance insert send the link to bot via `/indentify <token>` command

## TODO
- possibility to see recent author posts
- handle when someone likes/reposts your post
- show private post icon for such posts
- add choosing visibility for posts
- Parse of telegram message entities, like bold, links etc
- show audio title/artist in caption
- update help
- support different instances
- send reply id as html link
- oauth via phoenix server on subdomain
- PRs to Hunter to avoid using exceptions

## See also
[Used as reference](https://github.com/lubien/elixir-telegram-bot-boilerplate)

## License

[MIT](LICENSE.md)
