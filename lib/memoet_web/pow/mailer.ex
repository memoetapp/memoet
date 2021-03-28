defmodule MemoetWeb.Pow.Mailer do
  @moduledoc false

  use Pow.Phoenix.Mailer

  @impl true
  def cast(%{user: _user, subject: _subject, text: _text, html: _html} = params) do
    Memoet.Emails.cast(params)
  end

  @impl true
  def process(email) do
    Memoet.Emails.send(email)
    :ok
  end
end
