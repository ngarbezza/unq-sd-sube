defmodule Servidor do
  @moduledoc false

  @enforce_keys [:nombre]
  defstruct nombre: nil, transacciones: []

  def nuevo_servidor(nombre) do
    %Servidor{nombre: nombre}
  end

  def loop(servidor) do
    receive do
      # TODO: sincronizar con las transacciones de un expendedor
      #      {:sincronizar, expendedor, transacciones} ->
      #        expendedor |> send({:sincronizado, transacciones})
      #        loop(servidor.transacciones ++ transacciones)
    end
  end
end
