defmodule Expendedor do
  @moduledoc false

  import Tarjeta
  import CoreExtensions

  @enforce_keys [:nombre]
  defstruct nombre: nil, transacciones: [], servidores: []

  ## Supervisor

  alias Expendedor.Cache

  def iniciar(nombre) do
    Expendedor.Supervisor.start_link(nuevo_expendedor(nombre))
  end

  ## GenServer initialization

  use GenServer

  def start_link(cache_pid) do
    GenServer.start_link(__MODULE__, cache_pid)
  end

  def nuevo_expendedor(nombre), do: %Expendedor{nombre: nombre}

  # Client API

  def cobrar(pid, usuario, tarjeta, monto) do
    GenServer.cast(pid, {:cobrar, usuario, tarjeta, monto})
  end

  def registrar_servidor(pid, servidor) do
    GenServer.cast(pid, {:registrar, servidor})
  end

  def sincronizar(pid) do
    GenServer.cast(pid, {:iniciar_sincronizacion})
  end

  def sincronizacion_finalizada(pid, transacciones) do
    GenServer.cast(pid, {:sincronizacion_finalizada, transacciones})
  end

  def status(pid), do: GenServer.call(pid, {:status})

  # para simular una excepción
  def crash(pid), do: GenServer.cast(pid, {:crash})

  # Server (callbacks)

  @impl true
  def init(cache_pid) do
    expendedor = Cache.expendedor_para(cache_pid)
    {:ok, %{expendedor: expendedor, cache_pid: cache_pid}}
  end

  @impl true
  def handle_cast({:cobrar, usuario, tarjeta, monto}, estado) do
    chequear_estado_de_servidores(estado.expendedor)
    case cobrar_pasaje(estado.expendedor, tarjeta, monto) do
      {:ok, nuevo_expendedor} ->
        Usuario.descontar(usuario, monto)
        log_event(nuevo_expendedor, "Cobra en tarjeta ##{tarjeta.id} #{monto} pesos")
        nuevo_estado = put_in(estado.expendedor, nuevo_expendedor)
        {:noreply, nuevo_estado}

      {:error, expendedor} ->
        log_event(expendedor, "No puede cobrar #{monto} pesos en tarjeta ##{tarjeta.id}. Saldo insuficiente")
        {:noreply, estado}
    end
  end

  @impl true
  def handle_cast({:registrar, servidor}, estado) do
    nuevo_estado = put_in(estado.expendedor.servidores, [servidor | estado.expendedor.servidores])
    log_event(estado.expendedor, "Registrado servidor de sincronización #{inspect(servidor)}")
    {:noreply, nuevo_estado}
  end

  @impl true
  def handle_cast({:iniciar_sincronizacion}, estado) do
    chequear_estado_de_servidores(estado.expendedor)
    for servidor <- estado.expendedor.servidores do
      Servidor.sincronizar(servidor, self(), estado.expendedor.transacciones)
    end
    {:noreply, estado}
  end

  @impl true
  def handle_cast({:sincronizacion_finalizada, transacciones}, estado) do
    log_event(estado.expendedor, "#{length(transacciones)} Transaccion(es) sincronizada(s) correctamente.")
    nuevo_estado = put_in(estado.expendedor.transacciones, [])
    {:noreply, nuevo_estado}
  end

  @impl true
  def handle_cast({:crash}, _estado) do
    1/0
  end

  @impl true
  def handle_call({:status}, _from, estado) do
    message = "Status: #{length(estado.expendedor.servidores)} servidor(es), #{length(estado.expendedor.transacciones)} transaccion(es) pendiente(s)"
    log_event(estado.expendedor, message)
    {:reply, message, estado}
  end

  @impl true
  def terminate(_reason, estado) do
    log_event(estado.expendedor, "Finalizando proceso!")
    Cache.actualizar_expendedor(estado.expendedor, estado.cache_pid)
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
    nueva_transaccion = Transaccion.nueva_transaccion(tarjeta.id, monto)
    transacciones = [nueva_transaccion | expendedor.transacciones]
    put_in(expendedor.transacciones, transacciones)
  end

  defp log_event(expendedor, event_string) do
    EventLogger.event("EXPENDEDOR", expendedor.nombre, event_string)
  end
end
