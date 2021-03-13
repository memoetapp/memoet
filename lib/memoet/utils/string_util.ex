defmodule Memoet.Utils.StringUtil do
  @moduledoc """
  String utilities
  """

  @spec random_string(integer) :: String.t()
  def random_string(length) do
    :crypto.strong_rand_bytes(length)
    |> Base.url_encode64()
    |> binary_part(0, length)
  end

  @spec blank?(String.t() | nil) :: boolean
  def blank?(str_or_nil) do
    "" == str_or_nil |> to_string() |> String.trim()
  end

  def changeset_error_to_string(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
    |> Enum.reduce("", fn {k, v}, acc ->
      joined_errors = Enum.join(v, ", ")
      "#{acc}#{k}: #{joined_errors}; "
    end)
  end
end
