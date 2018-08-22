defmodule Usuario do
  @moduledoc false

  import Tarjeta

  @enforce_keys [:nombre, :tarjeta]
  defstruct [:nombre, :tarjeta]

  def nuevo_usuario(nombre, tarjeta), do: %Usuario{nombre: nombre, tarjeta: tarjeta}

  def loop(usuario) do
    receive do
      {:cargar, monto} -> cargar_tarjeta_y_continuar(usuario, monto)
      {:viajar, expendedor, monto} -> solicitar_viaje_y_continuar(usuario, expendedor, monto)
      {:descontar, monto} -> descontar_viaje_y_continuar(usuario, monto)
      {:saldo} -> informar_saldo_y_continuar(usuario)
    end
  end

  defp cargar_tarjeta_y_continuar(usuario, monto) do
    tarjeta = cargar(usuario.tarjeta, monto)

    put_in(usuario.tarjeta, tarjeta)
    |> log_event("Carga #{monto} pesos en tarjeta ##{tarjeta.id}. Saldo nuevo #{tarjeta.saldo} pesos")
    |> loop
  end

  defp solicitar_viaje_y_continuar(usuario, expendedor, monto) do
    Expendedor.cobrar(expendedor, self(), usuario.tarjeta, monto)

    usuario
    |> log_event("Solicita viaje por #{monto} pesos")
    |> loop
  end

  defp descontar_viaje_y_continuar(usuario, monto) do
    {:ok, tarjeta} = descontar(usuario.tarjeta, monto)

    put_in(usuario.tarjeta, tarjeta)
    |> log_event("Cobrados #{monto} pesos en tarjeta ##{tarjeta.id}. Saldo nuevo #{tarjeta.saldo} pesos")
    |> loop
  end

  defp informar_saldo_y_continuar(usuario) do
    usuario
    |> log_event("Saldo en tarjeta: #{usuario.tarjeta.saldo}")
    |> loop
  end

  defp log_event(usuario, event_string) do
    EventLogger.event("USUARIO", usuario.nombre, event_string, "\t\t\t")
    usuario
  end
end
