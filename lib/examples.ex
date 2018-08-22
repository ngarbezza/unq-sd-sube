defmodule Examples do
  @moduledoc false

  require Expendedor
  import Usuario
  import Tarjeta
  import Servidor

  # caso feliz, sin servidores
  def one do
    {:ok, l159} = Expendedor.iniciar("159 interno 8")
    pepa = spawn(Usuario, :loop, [nuevo_usuario("Pepa", nueva_tarjeta(1))])
    pepe = spawn(Usuario, :loop, [nuevo_usuario("Pepe", nueva_tarjeta(2))])

    pepa |> send({:cargar, 50})
    pepe |> send({:cargar, 20})
    pepe |> send({:viajar, l159, 10})
    Process.sleep(1000)
    pepe |> send({:viajar, l159, 10})
    Process.sleep(1000)
    pepe |> send({:viajar, l159, 10})
    Process.sleep(1000)
    pepa |> send({:viajar, l159, 20})

    Expendedor.status(l159)
    [l159, pepa, pepe]
  end

  # usuario sin saldo para viajar
  def two do
    {:ok, l159} = Expendedor.iniciar("159 interno 8")
    pepa = spawn(Usuario, :loop, [nuevo_usuario("Pepa", nueva_tarjeta(1))])

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

    Expendedor.status(l159)
    [l159, pepa]
  end

  # caso feliz, con servidores
  def three do
    {:ok, l159} = Expendedor.iniciar("159 interno 8")
    serv = Servidor |> spawn(:loop, [nuevo_servidor("Uno")])
    pepe = Usuario |> spawn(:loop, [nuevo_usuario("Pepe", nueva_tarjeta(2))])

    Expendedor.registrar_servidor(l159, serv)
    pepe |> send({:cargar, 20})
    pepe |> send({:viajar, l159, 10})
    Process.sleep(1000)
    pepe |> send({:viajar, l159, 10})
    Process.sleep(1000)
    pepe |> send({:viajar, l159, 10})
    Process.sleep(1000)

    Expendedor.status(l159)
    [l159, serv, pepe]
  end
end
