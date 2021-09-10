defmodule Memoet.Emails do
  @moduledoc false

  use Swoosh.Mailer, otp_app: :memoet
  import Swoosh.Email
  alias Memoet.Utils.EmailUtil

  require Logger
  require Sentry

  def cast(%{user: user, subject: subject, text: text, html: html}) do
    %Swoosh.Email{}
    |> to({"", user.email})
    |> from({"Memoet", "memoet@manhtai.com"})
    |> subject(subject)
    |> html_body(html)
    |> text_body(text)
  end

  def send(email) do
    # TODO: Move this to oban
    Task.start(fn ->
      email
      |> may_deliver()
      |> log_warnings()
    end)
  end

  defp may_deliver(email) do
    if has_valid_to_addresses?(email) do
      deliver(email)
    else
      {:error, "Skipped sending to potential invalid email: #{inspect(email.to)}"}
    end
  end

  defp has_valid_to_addresses?(email) do
    Enum.all?(email.to, fn {_name, address} ->
      EmailUtil.valid?(address)
    end)
  end

  defp log_warnings({:error, reason}) do
    Logger.warn("Mailer backend failed with: #{inspect(reason)}")
    Sentry.capture_exception(reason)
  end

  defp log_warnings({:ok, response}), do: {:ok, response}
end
