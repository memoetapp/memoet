defmodule Memoet.Utils.HtmlUtil do
  def to_html(markdown) do
    sanitized = HtmlSanitizeEx.markdown_html(markdown)
    Earmark.as_html!(sanitized, breaks: true)
  end
end
