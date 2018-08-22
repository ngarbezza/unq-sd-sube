defmodule Usuario do
  @moduledoc false

  @enforce_keys [:nombre, :tarjeta]
  defstruct [:nombre, :tarjeta]

  ## GenServer initialization

  use GenServer

  def iniciar(nombre, tarjeta) do
    GenServer.start_link(__MODULE__, nuevo_usuario(nombre, tarjeta))
  end

  def nuevo_usuario(nombre, tarjeta), do: %Usuario{nombre: nombre, tarjeta: tarjeta}

  # Client API

  def cargar(pid, monto), do: GenServer.cast(pid, {:cargar, monto})
  def viajar(pid, expendedor, monto), do: GenServer.cast(pid, {:viajar, expendedor, monto})
  def descontar(pid, monto), do: GenServer.cast(pid, {:descontar, monto})
  def saldo(pid), do: GenServer.call(pid, {:saldo})

  # Server (callbacks)

  @impl true
  def init(usuario), do: {:ok, usuario}

  @impl true
  def handle_cast({:cargar, monto}, usuario) do
    tarjeta = Tarjeta.cargar(usuario.tarjeta, monto)
    log_event(usuario, "Carga #{monto} pesos en tarjeta ##{tarjeta.id}. Saldo nuevo #{tarjeta.saldo} pesos")
    {:noreply, put_in(usuario.tarjeta, tarjeta)}
  end

  @impl true
  def handle_cast({:viajar, expendedor, monto}, usuario) do
    Expendedor.cobrar(expendedor, self(), usuario.tarjeta, monto)
    log_event(usuario, "Solicita viaje por #{monto} pesos")
    {:noreply, usuario}
  end

  @impl true
  def handle_cast({:descontar, monto}, usuario) do
    {:ok, tarjeta} = Tarjeta.descontar(usuario.tarjeta, monto)
    log_event(usuario, "Cobrados #{monto} pesos en tarjeta ##{tarjeta.id}. Saldo nuevo #{tarjeta.saldo} pesos")
    {:noreply, put_in(usuario.tarjeta, tarjeta)}
  end

  @impl true
  def handle_call({:saldo}, _from, usuario) do
    log_event(usuario, "Saldo en tarjeta: #{usuario.tarjeta.saldo} pesos")
    {:reply, usuario.tarjeta.saldo, usuario}
  end

  defp log_event(usuario, event_string) do
    EventLogger.event("USUARIO", usuario.nombre, event_string, "\t\t\t")
    usuario
  end
end
