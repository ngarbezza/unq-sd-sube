defmodule Expendedor do
  @moduledoc false

  require EventLogger

  import Tarjeta

  @enforce_keys [:nombre]
  defstruct transacciones: [], nombre: nil

  def nuevo_expendedor(nombre) do
    %Expendedor{nombre: nombre}
  end

  def cobrar_pasaje(expendedor, tarjeta, monto) do
    case descontar(tarjeta, monto) do
      {:ok, tarjeta} -> {:ok, transaccion_exitosa(expendedor, tarjeta, monto)}
      _ -> {:error, expendedor}
    end
  end

  def loop(expendedor) do
    receive do
      {:cobrar, usuario, tarjeta, monto} ->
        expendedor |> log_event("Cobra en tarjeta ##{tarjeta.id} #{monto} pesos")

        case cobrar_pasaje(expendedor, tarjeta, monto) do
          {:ok, expendedor} ->
            usuario |> send({:descontar, monto})
            loop(expendedor)

          _ ->
            loop(expendedor)
        end
    end
  end

  defp transaccion_exitosa(expendedor, tarjeta, monto) do
    nueva_transaccion = %Transaccion{tarjeta_id: tarjeta.id, monto: monto}
    transacciones = [nueva_transaccion | expendedor.transacciones]
    put_in(expendedor.transacciones, transacciones)
  end

  defp log_event(expendedor, event_string) do
    EventLogger.event("EXPENDEDOR", expendedor.nombre, event_string)
  end
end
