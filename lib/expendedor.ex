defmodule Expendedor do
  @moduledoc false

  import Tarjeta
  import Transaccion

  defstruct transacciones: [], nombre: nil

  def nuevo_expendedor(nombre) do
    %Expendedor{nombre: nombre}
  end

  def cobrar_pasaje(expendedor, tarjeta, monto) do
    case descontar(tarjeta, monto) do
      {:ok, tarjeta} -> transaccion_exitosa(expendedor, tarjeta, monto)
      _ -> expendedor
    end
  end

  defp transaccion_exitosa(expendedor, tarjeta, monto) do
    nueva_transaccion = %Transaccion{tarjeta_id: tarjeta.id, monto: monto}
    transacciones = expendedor.transacciones ++ [nueva_transaccion]
    put_in(expendedor.transacciones, transacciones)
  end

  def loop do
    receive do
      {:cobrar, usuario, tarjeta, monto} ->
        IO.puts("cobrar en tarjeta ##{tarjeta.id} #{monto} pesos")
        {:ok, tarjeta} = descontar(tarjeta, monto)
        send(usuario, {:descontar, monto, tarjeta})
        loop()
    end

    loop()
  end
end
