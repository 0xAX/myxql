defmodule MyXQL.Protocol.Types do
  @moduledoc false
  # https://dev.mysql.com/doc/internals/en/basic-types.html

  # https://dev.mysql.com/doc/internals/en/integer.html#fixed-length-integer
  defmacro uint(size) do
    quote do
      size(unquote(size)) - unit(8) - little
    end
  end

  defmacro int1(), do: quote(do: 8 - signed)
  defmacro uint1(), do: quote(do: 8)
  defmacro int2(), do: quote(do: 16 - little - signed)
  defmacro uint2(), do: quote(do: 16 - little)
  defmacro int3(), do: quote(do: 24 - little - signed)
  defmacro uint3(), do: quote(do: 24 - little)
  defmacro int4(), do: quote(do: 32 - little - signed)
  defmacro uint4(), do: quote(do: 32 - little)
  defmacro int8(), do: quote(do: 64 - little - signed)
  defmacro uint8(), do: quote(do: 64 - little)

  # https://dev.mysql.com/doc/internals/en/integer.html#packet-Protocol::LengthEncodedInteger
  def encode_int_lenenc(int) when int < 251, do: <<int>>
  def encode_int_lenenc(int) when int < 0xFFFF, do: <<0xFC, int::uint2>>
  def encode_int_lenenc(int) when int < 0xFFFFFF, do: <<0xFD, int::uint3>>
  def encode_int_lenenc(int) when int < 0xFFFFFFFFFFFFFFFF, do: <<0xFE, int::uint8>>

  def decode_int_lenenc(binary) do
    {integer, ""} = take_int_lenenc(binary)
    integer
  end

  def take_int_lenenc(binary) do
    binary_size_1 = :erlang.byte_size(binary) - 1
    binary_size_2 = :erlang.byte_size(binary) - 2 - 1
    binary_size_3 = :erlang.byte_size(binary) - 3 - 1
    binary_size_8 = :erlang.byte_size(binary) - 8 - 1
    case binary do
      <<int::uint1, rest::binary-size(binary_size_1)>> when int < 251 ->
        {int, rest}
      <<0xFC, int::uint2, rest::binary-size(binary_size_2)>> ->
        {int, rest}
      <<0xFD, int::uint3, rest::binary-size(binary_size_3)>> ->
        {int, rest}
      <<0xFE, int::uint8, rest::binary-size(binary_size_8)>> ->
        {int, rest}
    end
    # {rest, rest}
  end
  
  # def take_int_lenenc(<<int::uint1, rest::binary>>) when int < 251, do: {int, rest}
  # def take_int_lenenc(<<0xFC, int::uint2, rest::binary>>), do: {int, rest}
  # def take_int_lenenc(<<0xFD, int::uint3, rest::binary>>), do: {int, rest}
  # def take_int_lenenc(<<0xFE, int::uint8, rest::binary>>), do: {int, rest}

  # def take_int_lenenc_offset(<<>>, _), do: 0
  # def take_int_lenenc_offset(binary, offset) do #when int < 251 do
  #   if offset != 0 do
  #     case binary do
  #       <<_off::binary-size(offset), int::uint1, _rest::binary>> when int < 251 ->
  #         int + 1
  #       <<_off::binary-size(offset), 0xFC, int::uint2, _rest::binary>> when int < 251 ->
  #         int + 1
  #       <<_off::binary-size(offset), 0xFD, int::uint3, _rest::binary>> when int < 251 ->
  #         int + 1
  #       <<_off::binary-size(offset), 0xFE, int::uint8, _rest::binary>> when int < 251 ->
  #         int + 1
  #     end
  #   else
  #     case binary do
  #       <<int::uint1, _rest::binary>> when int < 251 ->
  #         int + 1
  #       <<0xFC, int::uint2, _rest::binary>> when int < 251 ->
  #         int + 2
  #       <<0xFD, int::uint3, _rest::binary>> when int < 251 ->
  #         int + 3
  #       <<0xFE, int::uint8, _rest::binary>> when int < 251 ->
  #         int + 8
  #     end
  #   end
  # end

  # def take_int_lenenc(<<0xFC, int::uint2, rest::binary>>, offset), do: int + 2
  # def take_int_lenenc(<<0xFD, int::uint3, rest::binary>>, offset), do: int + 3
  # def take_int_lenenc(<<0xFE, int::uint8, rest::binary>>, offset), do: int + 4
  
  # https://dev.mysql.com/doc/internals/en/string.html#packet-Protocol::FixedLengthString
  defmacro string(size) do
    quote do
      size(unquote(size)) - binary
    end
  end

  # https://dev.mysql.com/doc/internals/en/string.html#packet-Protocol::LengthEncodedString
  def encode_string_lenenc(binary) when is_binary(binary) do
    size = encode_int_lenenc(byte_size(binary))
    <<size::binary, binary::binary>>
  end

  def decode_string_lenenc(binary) do
    {_size, rest} = take_int_lenenc(binary)
    rest
  end

  # def take_string_lenenc_offset(<<>>, _), do: 0
  # def take_string_lenenc_offset(binary, offset) do
  #   :io.format("offset ~p~n", [offset])
  #   :io.format("binary ~p~n", [binary])
  #   r = take_int_lenenc_offset(binary, offset)
  #   :io.format("r ~p~n", [r])
  # end

  def take_string_lenenc(binary) do
    {size, rest} = take_int_lenenc(binary)
    rest_size = :erlang.byte_size(rest) - size
    <<string::string(size), rest::binary-size(rest_size)>> = rest
    {string, rest}
  end

  # https://dev.mysql.com/doc/internals/en/string.html#packet-Protocol::NulTerminatedString
  def decode_string_nul(binary) do
    {string, ""} = take_string_nul(binary)
    string
  end

  def take_string_nul(binary) do
    [string, rest] = :binary.split(binary, <<0>>)
    {string, rest}
  end
end
