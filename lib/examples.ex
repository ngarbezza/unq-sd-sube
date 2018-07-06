defmodule Examples do
  @moduledoc false

  import Usuario
  import Tarjeta
  import Expendedor
  import Servidor

  # caso feliz, sin servidores
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

    [l159, pepa, pepe]
  end

  # usuario sin saldo para viajar
  def two do
    l159 = Expendedor |> spawn(:loop, [nuevo_expendedor("159 interno 8")])
    pepa = Usuario |> spawn(:loop, [nuevo_usuario("Pepa", nueva_tarjeta(1))])

    # puede viajar
    pepa |> send({:viajar, l159, 15})
    Process.sleep(1000)
    # no puede
    pepa |> send({:viajar, l159, 10})
    Process.sleep(1000)
    # puede, porque llega hasta el limite
    pepa |> send({:viajar, l159, 5})
    Process.sleep(1000)
    # no puede
    pepa |> send({:viajar, l159, 10})
    Process.sleep(1000)

    [l159, pepa]
  end

  # caso feliz, con servidores
  def three do
    l159 = Expendedor |> spawn(:loop, [nuevo_expendedor("159 interno 8")])
    serv = Servidor |> spawn(:loop, [nuevo_servidor("Uno")])
    pepe = Usuario |> spawn(:loop, [nuevo_usuario("Pepe", nueva_tarjeta(2))])

    l159 |> send({:servidor, serv})
    pepe |> send({:cargar, 20})
    pepe |> send({:viajar, l159, 10})
    Process.sleep(1000)
    pepe |> send({:viajar, l159, 10})
    Process.sleep(1000)
    pepe |> send({:viajar, l159, 10})
    Process.sleep(1000)

    [l159, serv, pepe]
  end
end
