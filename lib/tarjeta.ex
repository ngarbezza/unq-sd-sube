defmodule Tarjeta do
  @moduledoc false

  defstruct id: nil, saldo: 0

  def nueva_tarjeta(id) do
    %Tarjeta{id: id}
  end

  def cargar(tarjeta, dinero) do
    put_in(tarjeta.saldo, tarjeta.saldo + dinero)
  end

  def descontar(tarjeta, dinero) do
    if puede_descontar(tarjeta, dinero) do
      {:ok, put_in(tarjeta.saldo, tarjeta.saldo - dinero)}
    else
      error_de_saldo_insuficiente()
    end
  end

  def error_de_saldo_insuficiente, do: {:error, "Saldo insuficiente"}

  defp puede_descontar(tarjeta, dinero) do
    saldo_minimo_permitido = -20
    tarjeta.saldo - dinero >= saldo_minimo_permitido
  end
end
