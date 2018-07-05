defmodule EventLogger do
  @moduledoc false

  def event(source, identifier, event_string) do
    IO.puts("#{source}\t\t#{identifier}\t\t#{event_string}")
  end
end
