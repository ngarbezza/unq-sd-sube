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
    servidor = put_in(servidor.transacciones, servidor.transacciones ++ transacciones)
    Expendedor.sincronizacion_finalizada(expendedor, transacciones)
    log_event(servidor, "#{length(transacciones)} nuevas transacciones")
    {:noreply, servidor }
  end

  defp log_event(servidor, event_string) do
    EventLogger.event("SERVIDOR", servidor.nombre, event_string)
  end
end
