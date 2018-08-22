defmodule Examples do
  @moduledoc false

  import Tarjeta

  # caso feliz, sin servidores
  def one do
    {:ok, l159} = Expendedor.iniciar("159 interno 8")
    {:ok, pepa} = Usuario.iniciar("Pepa", nueva_tarjeta(1))
    {:ok, pepe} = Usuario.iniciar("Pepe", nueva_tarjeta(2))

    Usuario.cargar(pepa, 50)
    Usuario.cargar(pepe, 20)

    Usuario.viajar(pepe, l159, 10); pause()
    Usuario.viajar(pepe, l159, 10); pause()
    Usuario.viajar(pepe, l159, 10); pause()
    Usuario.viajar(pepa, l159, 10)

    Expendedor.status(l159)
    Usuario.saldo(pepa)
    Usuario.saldo(pepe)
    [l159, pepa, pepe]
  end

  # usuario sin saldo para viajar
  def two do
    {:ok, l159} = Expendedor.iniciar("159 interno 8")
    {:ok, pepa} = Usuario.iniciar("Pepa", nueva_tarjeta(1))

    Usuario.viajar(pepa, l159, 15); pause() # puede viajar
    Usuario.viajar(pepa, l159, 10); pause() # no puede
    Usuario.viajar(pepa, l159, 5); pause() # puede, porque llega hasta el limite
    Usuario.viajar(pepa, l159, 10); pause() # no puede

    Usuario.saldo(pepa)
    Expendedor.status(l159)
    [l159, pepa]
  end

  # caso feliz, con servidores
  def three do
    {:ok, l159} = Expendedor.iniciar("159 interno 8")
    {:ok, serv} = Servidor.iniciar("Uno")
    {:ok, pepe} = Usuario.iniciar("Pepe", nueva_tarjeta(2))

    Expendedor.registrar_servidor(l159, serv)
    Usuario.cargar(pepe, 20)
    Usuario.viajar(pepe, l159, 10); pause()
    Usuario.viajar(pepe, l159, 10); pause()
    Usuario.viajar(pepe, l159, 10); pause()

    Expendedor.status(l159)
    Expendedor.sincronizar(l159); pause()
    Expendedor.status(l159)
    [l159, serv, pepe]
  end

  defp pause(msec \\ 1000), do: Process.sleep(msec)
end
