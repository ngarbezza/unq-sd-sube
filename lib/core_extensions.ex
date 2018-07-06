defmodule CoreExtensions do
  @moduledoc false

  defmacro not_nil(value) do
    quote do: !is_nil(unquote(value))
  end

  defmacro is_empty(list) do
    quote do: unquote(list) == []
  end

  defmacro if_empty(clause, do: expression) do
    quote do: if(is_empty(unquote(clause)), do: unquote(expression))
  end
end
