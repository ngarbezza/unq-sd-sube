defmodule Expendedor.Supervisor do
  use Supervisor

  def expendedor_child_process(sup) do
    {_, child, _, _} = List.keyfind(Supervisor.which_children(sup), Expendedor, 0)
    child
  end

  def start_link(expendedor) do
    {:ok, sup} = Supervisor.start_link(__MODULE__, [expendedor])
    start_children(sup, expendedor)

    {:ok, sup, expendedor_child_process(sup)}
  end

  def start_children(sup, expendedor) do
    {:ok, cache_pid} = Supervisor.start_child(sup, worker(Expendedor.Cache, [expendedor]))
    Supervisor.start_child(sup, worker(Expendedor, [cache_pid]))
  end

  def init(_) do
    supervise([], strategy: :one_for_one)
  end
end