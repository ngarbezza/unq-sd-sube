defmodule Examples do
  @moduledoc false

  import Usuario
  import Tarjeta
  import Expendedor

  def one do
    l159 = Expendedor |> spawn(:loop, [nuevo_expendedor("159 interno 8")])
    pepa = Usuario |> spawn(:loop, [nuevo_usuario("Pepa", nueva_tarjeta(1))])
    pepe = Usuario |> spawn(:loop, [nuevo_usuario("Pepe", nueva_tarjeta(2))])

    pepa |> send({:cargar, 50})
    pepe |> send({:cargar, 20})
    pepe |> send({:viajar, l159, 10})
    Process.sleep(1000)
    pepe |> send({:viajar, l159, 10})
    Process.sleep(1000)
    pepe |> send({:viajar, l159, 10})
    Process.sleep(1000)
    pepa |> send({:viajar, l159, 20})
  end
end
