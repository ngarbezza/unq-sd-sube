defmodule UsuarioTest do
  use ExUnit.Case
  import Tarjeta

  test "inicia con saldo $0" do
    tarjeta = nueva()
    assert saldo(tarjeta) == 0
  end

  test "puedo cargar dinero" do
    tarjeta = cargar(nueva(), 20)
    assert saldo(tarjeta) == 20
    tarjeta = cargar(tarjeta, 20)
    assert saldo(tarjeta) == 40
  end

  test "puedo descontar dinero si el saldo es positivo" do
    tarjeta = cargar(nueva(), 20)
    tarjeta = descontar(tarjeta, 10.5)
    assert saldo(tarjeta) == 9.5
  end

  test "puedo descontar dinero dentro de un saldo negativo permitido" do
    tarjeta = nueva()
    tarjeta = descontar(tarjeta, 20)
    assert saldo(tarjeta) == -20
  end

  test "no puedo descontar dinero mas alla del saldo negativo permitido" do
    tarjeta = nueva()
    assert_raise RuntimeError, "Saldo insuficiente", fn -> descontar(tarjeta, 21) end
  end
end
