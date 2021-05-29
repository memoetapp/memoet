defmodule Memoet.Str do
  @moduledoc """
  String utilities
  """
  @num_regex ~r/(?<sign>-?)(?<int>\d+)(\.(?<frac>\d+))?/

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

  def format_number(number, options \\ []) do
    thousands_separator = Keyword.get(options, :thousands_separator, ",")
    parts = Regex.named_captures(@num_regex, to_string(number))

    formatted_int =
      parts["int"]
      |> String.graphemes()
      |> Enum.reverse()
      |> Enum.chunk_every(3)
      |> Enum.join(thousands_separator)
      |> String.reverse()

    decimal_separator =
      if parts["frac"] == "" do
        ""
      else
        Keyword.get(options, :decimal_separator, ".")
      end

    to_string([parts["sign"], formatted_int, decimal_separator, parts["frac"]])
  end
end
