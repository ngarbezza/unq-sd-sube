defmodule Usuario do
  @moduledoc false

  import Tarjeta

  def loop(tarjeta) do
    receive do
      {:cargar, monto} ->
        tarjeta = cargar(tarjeta, monto)

        IO.puts(
          "cargados #{monto} pesos en tarjeta ##{tarjeta.id}. Saldo nuevo #{tarjeta.saldo} pesos"
        )

        loop(tarjeta)

      {:viajar, expendedor, monto} ->
        IO.puts("Viajando por #{monto} pesos")
        send(expendedor, {:cobrar, self(), tarjeta, monto})
        loop(tarjeta)

      {:descontar, monto, tarjeta} ->
        IO.puts(
          "Me cobraron #{monto} pesos en tarjeta ##{tarjeta.id}. Saldo nuevo #{tarjeta.saldo} pesos"
        )

        loop(tarjeta)
    end
  end
end
