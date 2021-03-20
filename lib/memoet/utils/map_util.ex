defmodule Memoet.Utils.MapUtil do

  def from_struct(struct) do
    Map.from_struct(struct)
    |> Enum.map(fn {k, v} -> {Atom.to_string(k), v} end)
    |> Enum.into(%{})
  end
end
