defmodule Bleroma.Commands.Outside do
  # Notice that here we just `use` Commander. Router is only
  # used to map commands to actions. It's best to keep routing
  # only in Bleroma.Commands file. Commander gives us helpful
  # macros to deal with Nadia functions.
  use Bleroma.Commander

  # Functions must have as first parameter a variable named
  # update. Otherwise, macros (like `send_message`) will not
  # work as expected.
  def outside(update) do
    Logger.log(:info, "Command /outside")

    send_message("This came from a separate module.")
  end
end
