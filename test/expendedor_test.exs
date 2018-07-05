defmodule ExpendedorTest do
  use ExUnit.Case, async: true
  use ExMatchers

  import Expendedor
  import Tarjeta

  defp un_expendedor_nuevo_cualquiera do
    nuevo_expendedor("159 interno 8")
  end

  test "expendedor inicialmente no posee transacciones" do
    expect un_expendedor_nuevo_cualquiera().transacciones, to: be_empty()
  end

  test "cobra un pasaje en una tarjeta y guarda la transacción" do
    expendedor = un_expendedor_nuevo_cualquiera()
    tarjeta = cargar(nueva_tarjeta(1), 20)
    {status, expendedor} = cobrar_pasaje(expendedor, tarjeta, 10)

    expect status, to: eq(:ok)
    expect expendedor.transacciones, to: include(%Transaccion{tarjeta_id: 1, monto: 10})
  end

  test "cuando no hay saldo disponible, no cobra el pasaje ni registra la transacción" do
    expendedor = un_expendedor_nuevo_cualquiera()
    tarjeta = cargar(nueva_tarjeta(1), 10)
    {status, expendedor} = cobrar_pasaje(expendedor, tarjeta, 31)

    expect status, to: eq(:error)
    expect expendedor.transacciones, to: be_empty()
  end
end
