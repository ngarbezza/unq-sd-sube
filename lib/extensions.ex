defmodule Extensions do
  @moduledoc false

  defmacro not_nil(value) do
    quote do: !is_nil(unquote(value))
  end
end
