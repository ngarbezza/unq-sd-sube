defmodule ExpendedorTest do
  use ExUnit.Case, async: true
  import Expendedor
  import Tarjeta
  import Transaccion

  defp unExpendedorNuevoCualquiera do
    nuevo_expendedor("159 interno 8")
  end

  test "expendedor inicialmente no posee transacciones" do
    assert unExpendedorNuevoCualquiera().transacciones == []
  end

  test "cobra un pasaje en una tarjeta y guarda la transacción" do
    expendedor = unExpendedorNuevoCualquiera()
    tarjeta = cargar(nueva_tarjeta(1), 20)

    expendedor = cobrar_pasaje(expendedor, tarjeta, 10)
    assert expendedor.transacciones == [%Transaccion{tarjeta_id: 1, monto: 10}]
  end

  test "cuando no hay saldo disponible, no cobra el pasaje ni registra la transacción" do
    expendedor = unExpendedorNuevoCualquiera()
    tarjeta = cargar(nueva_tarjeta(1), 10)

    expendedor = cobrar_pasaje(expendedor, tarjeta, 31)
    assert expendedor.transacciones == []
  end
end
