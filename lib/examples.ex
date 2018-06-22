defmodule Examples do
  @moduledoc false

  import Tarjeta

  def one do
    l159 = spawn(Expendedor, :loop, [])
    pepa = spawn(Usuario, :loop, [nueva_tarjeta(1)])
    pepe = spawn(Usuario, :loop, [nueva_tarjeta(2)])

    send(pepa, {:cargar, 50})
    send(pepe, {:cargar, 20})
    send(pepe, {:viajar, l159, 10})
    send(pepe, {:viajar, l159, 10})
    send(pepe, {:viajar, l159, 10})
    send(pepa, {:viajar, l159, 20})
  end
end
