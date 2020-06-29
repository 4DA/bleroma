defmodule Bleroma.Connection do
  require Hunter
  defstruct client: %Hunter.Client{}, tg_id: 0, acct: ""
end
