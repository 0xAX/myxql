defmodule MyXQL.Protocol.ValuesNif do
  use Rustler, otp_app: :myxql, crate: "myxql_nif"

  def take_int_lenenc_nif(_binary) do
    :erlang.nif_error(:nif_not_loaded)
  end
end
