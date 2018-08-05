defmodule Expendedor do
  @moduledoc false

  require EventLogger

  import Tarjeta
  import CoreExtensions

  @enforce_keys [:nombre]
  defstruct nombre: nil, transacciones: [], servidores: []

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
    if_empty(expendedor.servidores) do
      expendedor |> log_event("Sin servidores de sincronización!!")
    end

    receive do
      {:cobrar, usuario, tarjeta, monto} ->
        case cobrar_pasaje(expendedor, tarjeta, monto) do
          {:ok, expendedor} ->
            usuario |> send({:descontar, monto})

            expendedor
            |> log_event("Cobra en tarjeta ##{tarjeta.id} #{monto} pesos")
            |> loop

          {:error, expendedor} ->
            expendedor
            |> log_event("No puede cobrar #{monto} pesos en tarjeta ##{tarjeta.id}. Saldo insuficiente")
            |> loop
        end

      {:servidor, servidor} ->
        expendedor.servidores
        |> put_in([servidor | expendedor.servidores])
        |> log_event("Registrado servidor de sincronización #{servidor.nombre}")
        |> loop

      {:status} ->
        expendedor
        |> log_event("Status: #{length(expendedor.servidores)} servidor(es), #{length(expendedor.transacciones)} transaccion(es) pendiente(s)")
    end
  end

  defp transaccion_exitosa(expendedor, tarjeta, monto) do
    nueva_transaccion = %Transaccion{tarjeta_id: tarjeta.id, monto: monto}
    transacciones = [nueva_transaccion | expendedor.transacciones]
    put_in(expendedor.transacciones, transacciones)
  end

  defp log_event(expendedor, event_string) do
    EventLogger.event("EXPENDEDOR", expendedor.nombre, event_string)
    expendedor
  end
end
