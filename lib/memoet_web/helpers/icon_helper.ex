defmodule MemoetWeb.IconHelper do
  @moduledoc """
  Helper module for rendering icons as inline SVG.
  Place your icons in priv/icons folder.
  # Usage
      render_icon(:icon_name)
      #=> {:safe, "<svg ..."}
  """

  require EEx

  @paths [
    Path.join(:code.priv_dir(:memoet), "icons")
  ]

  for path <- @paths do
    File.ls!(path)
    |> Enum.filter(fn filename -> filename =~ ~r{\.svg$} end)
    |> Enum.each(fn filename ->
      path = Path.join(path, filename)
      name = filename |> String.replace(".svg", "") |> String.replace("-", "_")
      eex = EEx.compile_file(path, [])

      def render_icon(unquote(String.to_atom(name))) do
        {:safe, unquote(eex)}
      end
    end)
  end
end
