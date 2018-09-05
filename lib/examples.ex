defmodule Examples do
  @moduledoc false

  import Tarjeta

  # caso feliz, sin servidores
  # [e159, pepa, pepe] = Examples.one()
  def one do
    {:ok, _, e159} = Expendedor.iniciar("159 interno 8")

    {:ok, pepa} = Usuario.iniciar("Pepa", nueva_tarjeta(1))
    {:ok, pepe} = Usuario.iniciar("Pepe", nueva_tarjeta(2))

    Usuario.cargar(pepa, 50)
    Usuario.cargar(pepe, 20)

    Usuario.viajar(pepe, e159, 10); pause()
    Usuario.viajar(pepe, e159, 10); pause()
    Usuario.viajar(pepe, e159, 10); pause()
    Usuario.viajar(pepa, e159, 10)

    Expendedor.status(e159)
    Usuario.saldo(pepa)
    Usuario.saldo(pepe)
    [e159, pepa, pepe]
  end

  # usuario sin saldo para viajar
  # [e159, pepa] = Examples.two()
  def two do
    {:ok, _, e159} = Expendedor.iniciar("159 interno 8")
    {:ok, pepa} = Usuario.iniciar("Pepa", nueva_tarjeta(1))

    Usuario.viajar(pepa, e159, 15); pause() # puede viajar
    Usuario.viajar(pepa, e159, 10); pause() # no puede
    Usuario.viajar(pepa, e159, 5); pause() # puede, porque llega hasta el limite
    Usuario.viajar(pepa, e159, 10); pause() # no puede

    Usuario.saldo(pepa)
    Expendedor.status(e159)
    [e159, pepa]
  end

  # caso feliz, con servidores
  # [e159, serv, pepe] = Examples.three()
  def three do
    {:ok, _, e159} = Expendedor.iniciar("159 interno 8")
    {:ok, serv} = Servidor.iniciar("Uno")
    {:ok, pepe} = Usuario.iniciar("Pepe", nueva_tarjeta(2))

    Expendedor.registrar_servidor(e159, serv)
    Usuario.cargar(pepe, 20)
    Usuario.viajar(pepe, e159, 10); pause()
    Usuario.viajar(pepe, e159, 10); pause()
    Usuario.viajar(pepe, e159, 10); pause()

    Expendedor.status(e159)
    Expendedor.sincronizar(e159); pause()
    Expendedor.status(e159)
    [e159, serv, pepe]
  end

  # caso donde crashea el expendedor
  # [e159, serv, pepe] = Examples.four()
  def four do
    {:ok, sup, e159} = Expendedor.iniciar("159 interno 8")
    {:ok, serv} = Servidor.iniciar("Uno")
    {:ok, pepe} = Usuario.iniciar("Pepe", nueva_tarjeta(2))

    Expendedor.registrar_servidor(e159, serv)
    Usuario.cargar(pepe, 20)
    Usuario.viajar(pepe, e159, 10); pause()
    Usuario.viajar(pepe, e159, 10); pause()
    Usuario.viajar(pepe, e159, 10); pause()

    Expendedor.status(e159)
    Expendedor.sincronizar(e159); pause()
    ### Acá esperamos que falle y se restartee
    Expendedor.crash(e159); pause()
    ### Recuperamos el nuevo PID
    e159 = Expendedor.Supervisor.expendedor_child_process(sup)
    ### Podemos seguir operando con ese PID
    Expendedor.status(e159)
    [e159, serv, pepe]
  end

  defp pause(msec \\ 1000), do: :timer.sleep(msec)
end
