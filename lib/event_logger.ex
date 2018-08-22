defmodule EventLogger do
  @moduledoc false

  def event(source, identifier, event_string, separator \\ "\t\t") do
    IO.puts("#{source}#{separator}#{identifier}#{separator}#{event_string}")
  end
end
