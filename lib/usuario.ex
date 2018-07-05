defmodule Usuario do
  @moduledoc false

  require EventLogger

  import Tarjeta

  @enforce_keys [:nombre, :tarjeta]
  defstruct [:nombre, :tarjeta]

  def nuevo_usuario(nombre, tarjeta) do
    %Usuario{nombre: nombre, tarjeta: tarjeta}
  end

  def loop(usuario) do
    receive do
      {:cargar, monto} ->
        usuario |> cargar_tarjeta_y_continuar(monto)

      {:viajar, expendedor, monto} ->
        usuario |> solicitar_viaje_y_continuar(expendedor, monto)

      {:descontar, monto} ->
        usuario |> descontar_viaje_y_continuar(monto)
    end
  end

  defp cargar_tarjeta_y_continuar(usuario, monto) do
    tarjeta = cargar(usuario.tarjeta, monto)
    usuario = put_in(usuario.tarjeta, tarjeta)

    usuario |> log_event("Carga #{monto} pesos en tarjeta ##{tarjeta.id}. Saldo nuevo #{tarjeta.saldo} pesos")

    loop(usuario)
  end

  defp solicitar_viaje_y_continuar(usuario, expendedor, monto) do
    usuario |> log_event("Solicita viaje por #{monto} pesos")

    expendedor |> send({:cobrar, self(), usuario.tarjeta, monto})

    loop(usuario)
  end

  defp descontar_viaje_y_continuar(usuario, monto) do
    {:ok, tarjeta} = descontar(usuario.tarjeta, monto)
    usuario = put_in(usuario.tarjeta, tarjeta)

    usuario |> log_event("Cobrados #{monto} pesos en tarjeta ##{tarjeta.id}. Saldo nuevo #{tarjeta.saldo} pesos")

    loop(usuario)
  end

  defp log_event(usuario, event_string) do
    EventLogger.event("USUARIO", usuario.nombre, event_string)
  end
end
