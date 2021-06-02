defmodule MemoetWeb.StringHelper do
  @moduledoc """
  Convert markdown to html
  """
  def md_to_html(markdown) do
    html = Earmark.as_html!(markdown, breaks: true)
    HtmlSanitizeEx.markdown_html(html)
  end
end
