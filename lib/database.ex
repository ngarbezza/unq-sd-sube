use Amnesia

defdatabase Database do
  deftable Transaccion, [:id, :monto, :tarjeta_id], type: :set
end
