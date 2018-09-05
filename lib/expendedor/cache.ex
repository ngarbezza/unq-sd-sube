defmodule Expendedor.Cache do
  use GenServer

  def start_link(nombre) do
    GenServer.start_link(__MODULE__, nombre)
  end

  def init(nombre) do
    {:ok, nombre}
  end

  def expendedor_para(pid) do
    GenServer.call pid, :get
  end

  def actualizar_expendedor(nuevo_expendedor, pid) do
    GenServer.cast(pid, {:save, nuevo_expendedor})
  end

  def handle_call(:get, _from, expendedor) do
    IO.puts("### cache read, expendedor #{inspect(expendedor)}")
    {:reply, expendedor, expendedor}
  end

  def handle_cast({:save, nuevo_expendedor}, _expendedor) do
    IO.puts("### cache write, expendedor #{inspect(nuevo_expendedor)}")
    {:noreply, nuevo_expendedor}
  end
end