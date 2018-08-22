defmodule Expendedor do
  @moduledoc false

  require EventLogger

  import Tarjeta
  import CoreExtensions

  @enforce_keys [:nombre]
  defstruct nombre: nil, transacciones: [], servidores: []

  ## GenServer initialization

  use GenServer

  def iniciar(nombre) do
    GenServer.start_link(__MODULE__, nuevo_expendedor(nombre))
  end

  def nuevo_expendedor(nombre) do
    %Expendedor{nombre: nombre}
  end

  # Client API

  def cobrar(pid, usuario, tarjeta, monto) do
    GenServer.cast(pid, {:cobrar, usuario, tarjeta, monto})
  end

  def registrar_servidor(pid, servidor) do
    GenServer.cast(pid, {:registrar, servidor})
  end

  def status(pid) do
    GenServer.call(pid, {:status})
  end

  # Server (callbacks)

  @impl true
  def init(expendedor) do
    {:ok, expendedor}
  end

  @impl true
  def handle_cast({:cobrar, usuario, tarjeta, monto}, expendedor) do
    chequear_estado_de_servidores(expendedor)
    case cobrar_pasaje(expendedor, tarjeta, monto) do
      {:ok, expendedor} ->
        send(usuario, {:descontar, monto})
        log_event(expendedor, "Cobra en tarjeta ##{tarjeta.id} #{monto} pesos")
        {:noreply, expendedor}

      {:error, expendedor} ->
        log_event(expendedor, "No puede cobrar #{monto} pesos en tarjeta ##{tarjeta.id}. Saldo insuficiente")
        {:noreply, expendedor}
    end
  end

  @impl true
  def handle_cast({:registrar, servidor}, expendedor) do
    expendedor = put_in(expendedor.servidores, [servidor | expendedor.servidores])
    log_event(expendedor, "Registrado servidor de sincronización #{inspect(servidor)}")
    {:noreply, expendedor}
  end

  @impl true
  def handle_call({:status}, _from, expendedor) do
    message = "Status: #{length(expendedor.servidores)} servidor(es), #{length(expendedor.transacciones)} transaccion(es) pendiente(s)"
    log_event(expendedor, message)
    {:reply, message, expendedor}
  end

  def cobrar_pasaje(expendedor, tarjeta, monto) do
    case descontar(tarjeta, monto) do
      {:ok, tarjeta} -> {:ok, transaccion_exitosa(expendedor, tarjeta, monto)}
      _ -> {:error, expendedor}
    end
  end

  defp chequear_estado_de_servidores(expendedor) do
    if_empty(expendedor.servidores, do: log_event(expendedor, "Sin servidores de sincronización!!"))
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
