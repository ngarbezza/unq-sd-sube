defmodule Transaccion do
  @moduledoc false

  @enforce_keys [:tarjeta_id, :monto]
  defstruct [:tarjeta_id, :monto, :id]

  def nueva_transaccion(tarjeta_id, monto) do
    %Transaccion{tarjeta_id: tarjeta_id, monto: monto, id: UUID.uuid1()}
  end
end
