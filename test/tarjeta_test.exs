defmodule TarjetaTest do
  use ExUnit.Case, async: true
  import Tarjeta

  test "posee un id determinado al momento de la creación" do
    tarjeta = nuevaTarjeta(1)
    assert tarjeta.id == 1
  end

  test "inicia con saldo $0" do
    tarjeta = nuevaTarjeta(1)
    assert tarjeta.saldo == 0
  end

  test "puedo cargar dinero" do
    tarjeta = cargar(nuevaTarjeta(1), 20)
    assert tarjeta.saldo == 20
    tarjeta = cargar(tarjeta, 20)
    assert tarjeta.saldo == 40
  end

  test "puedo descontar dinero si el saldo es positivo" do
    tarjeta = cargar(nuevaTarjeta(1), 20)
    {status, tarjeta} = descontar(tarjeta, 10.5)
    assert status == :ok
    assert tarjeta.saldo == 9.5
  end

  test "puedo descontar dinero dentro de un saldo negativo permitido" do
    tarjeta = nuevaTarjeta(1)
    {status, tarjeta} = descontar(tarjeta, 20)
    assert status == :ok
    assert tarjeta.saldo == -20
  end

  test "no puedo descontar dinero mas alla del saldo negativo permitido" do
    tarjeta = cargar(nuevaTarjeta(1), 20)
    respuesta = descontar(tarjeta, 41)
    assert respuesta == errorDeSaldoInsuficiente()
    assert tarjeta.saldo == 20
  end
end
