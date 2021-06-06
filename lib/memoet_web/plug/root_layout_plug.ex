defmodule MemoetWeb.Plugs.RootLayoutPlug do
  def init(options), do: options

  def call(conn, _opts) do
    Phoenix.Controller.put_root_layout(conn, {MemoetWeb.LayoutView, :root})
  end
end
