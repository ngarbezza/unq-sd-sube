defmodule Servidor do
  @moduledoc false

  @enforce_keys [:nombre]
  defstruct nombre: nil, transacciones: []

  ## GenServer initialization

  use GenServer

  def iniciar(nombre) do
    GenServer.start_link(__MODULE__, nuevo_servidor(nombre))
  end

  def nuevo_servidor(nombre), do: %Servidor{nombre: nombre}

  # Client API

  def sincronizar(pid, expendedor, transacciones) do
    GenServer.cast(pid, {:sincronizar, expendedor, transacciones})
  end

  # Server (callbacks)

  @impl true
  def init(servidor), do: {:ok, servidor}

  @impl true
  def handle_cast({:sincronizar, expendedor, transacciones}, servidor) do
    case persistir_transacciones(transacciones) do
      {:atomic, :ok} ->
        servidor = put_in(servidor.transacciones, servidor.transacciones ++ transacciones)
        Expendedor.sincronizacion_finalizada(expendedor, transacciones)
        log_event(servidor, "#{length(transacciones)} nuevas transacciones")
        {:noreply, servidor}
      error ->
        log_event(servidor, "Falló la persistencia de transacciones: #{inspect(error)}")
        {:noreply, servidor}
    end
  end

  defp persistir_transacciones(transacciones) do
    :mnesia.transaction(fn ->
      Enum.each transacciones, fn(transaccion) ->
        Transaccion.write_to_db(transaccion)
      end
    end)
  end

  defp log_event(servidor, event_string) do
    EventLogger.event("SERVIDOR", servidor.nombre, event_string)
  end
end
