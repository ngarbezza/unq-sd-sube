defmodule TransaccionTest do
  use ExUnit.Case, async: true

  import Transaccion
  import CoreExtensions

  test "crea una transaccion con un id" do
    transaccion = nueva_transaccion(1, 10)
    assert not_nil(transaccion.id)
  end
end
