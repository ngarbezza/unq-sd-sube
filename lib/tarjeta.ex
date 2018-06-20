defmodule Tarjeta do
  defstruct id: nil, saldo: 0

  def nuevaTarjeta(id) do
    %Tarjeta{ id: id }
  end

  def cargar(tarjeta, dinero) do
    put_in tarjeta.saldo, tarjeta.saldo + dinero
  end

  def descontar(tarjeta, dinero) do
    if puede_descontar(tarjeta, dinero) do
      {:ok, put_in(tarjeta.saldo, tarjeta.saldo - dinero)}
    else
      errorDeSaldoInsuficiente()
    end
  end

  def errorDeSaldoInsuficiente, do: {:error, "Saldo insuficiente"}

  defp puede_descontar(tarjeta, dinero) do
    saldo_minimo_permitido = -20
    tarjeta.saldo - dinero >= saldo_minimo_permitido
  end
end
