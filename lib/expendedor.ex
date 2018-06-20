defmodule Expendedor do
  import Tarjeta
  import Transaccion

  defstruct transacciones: [], nombre: nil

  def nuevoExpendedor(nombre) do
    %Expendedor{ nombre: nombre }
  end

  def cobrarPasaje(expendedor, tarjeta, monto) do
    case descontar(tarjeta, monto) do
      {:ok, tarjeta} -> transaccionExitosa(expendedor, tarjeta, monto)
      _              -> expendedor
    end
  end

  defp transaccionExitosa(expendedor, tarjeta, monto) do
    nuevaTransaccion = %Transaccion{idTarjeta: tarjeta.id, monto: monto}
    put_in expendedor.transacciones , expendedor.transacciones ++ [nuevaTransaccion]
  end
end
