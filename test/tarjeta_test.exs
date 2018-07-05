defmodule TarjetaTest do
  use ExUnit.Case, async: true
  use ExMatchers

  import Tarjeta

  test "posee un id determinado al momento de la creación" do
    tarjeta = nueva_tarjeta(1)

    expect tarjeta.id, to: eq(1)
  end

  test "inicia con saldo $0" do
    tarjeta = nueva_tarjeta(1)
    expect tarjeta.saldo, to: eq(0)
  end

  test "puedo cargar dinero" do
    tarjeta = cargar(nueva_tarjeta(1), 20)
    expect tarjeta.saldo, to: eq(20)
    tarjeta = cargar(tarjeta, 20)
    expect tarjeta.saldo, to: eq(40)
  end

  test "puedo descontar dinero si el saldo es positivo" do
    tarjeta = cargar(nueva_tarjeta(1), 20)
    {status, tarjeta} = descontar(tarjeta, 10.5)

    expect status, to: eq(:ok)
    expect tarjeta.saldo, to: eq(9.5)
  end

  test "puedo descontar dinero dentro de un saldo negativo permitido" do
    tarjeta = nueva_tarjeta(1)
    {status, tarjeta} = descontar(tarjeta, 20)

    expect status, to: eq(:ok)
    expect tarjeta.saldo, to: eq(-20)
  end

  test "no puedo descontar dinero mas alla del saldo negativo permitido" do
    tarjeta = cargar(nueva_tarjeta(1), 20)
    respuesta = descontar(tarjeta, 41)

    expect respuesta, to: eq(error_de_saldo_insuficiente())
    expect tarjeta.saldo, to: eq(20)
  end
end
