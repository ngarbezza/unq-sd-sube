defmodule Tarjeta do
  def nueva do
    %{ saldo: 0 }
  end

  def saldo(tarjeta) do
    tarjeta.saldo
  end

  def cargar(tarjeta, dinero) do
    put_in tarjeta.saldo, tarjeta.saldo + dinero
  end

  def descontar(tarjeta, dinero) do
    unless puede_descontar(tarjeta, dinero) do raise "Saldo insuficiente" end

    put_in tarjeta.saldo, tarjeta.saldo - dinero
  end

  defp puede_descontar(tarjeta, dinero) do
    saldo_minimo_permitido = -20
    tarjeta.saldo - dinero >= saldo_minimo_permitido
  end
end
