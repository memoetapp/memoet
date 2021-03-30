NimbleCSV.define(Memoet.Decks.Import.ExcelCSV,
  separator: ";",
  escape: "\"",
  line_separator: "\r\n",
  moduledoc: false
)


defmodule Memoet.Decks.Import do
  @moduledoc false

  # [title, image, content, type, op1, op2, op3, op4, op5, correct_op, hint]
  @columns 11

  require Logger
  require Sentry

  alias Memoet.Repo
  alias Memoet.Notes
  alias Memoet.Notes.Types
  alias Memoet.Utils.StringUtil

  def import_csv(deck, filename) do
    Repo.transaction(
      fn ->
        try do
          import_csv!(deck, filename)
        rescue
          e ->
            Logger.error(e)
            Sentry.capture_exception(e, [stacktrace: __STACKTRACE__, extra: %{deck_id: deck.id}])
            Repo.rollback(e.message)
        end
      end,
      timeout: :infinity,
      pool_timeout: :infinity
    )
    |> case do
      {:ok, _} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end

  defp import_csv!(deck, filename) do
    parser = determine_parser(filename)

    File.stream!(filename)
    |> parser.parse_stream()
    |> Stream.map(fn [title, image, content, type, op1, op2, op3, op4, op5, correct_op, hint] ->
      params = %{
        "title" => (if StringUtil.blank?(title), do: "No title", else: title),
        "image" => image,
        "content" => content,
        "type" => Types.detect(type),
        "options" => [
          %{"content" => op1, "correct" => correct_op == "1"},
          %{"content" => op2, "correct" => correct_op == "2"},
          %{"content" => op3, "correct" => correct_op == "3"},
          %{"content" => op4, "correct" => correct_op == "4"},
          %{"content" => op5, "correct" => correct_op == "5"},
        ],
        "hint" => hint,
        "user_id" => deck.user_id,
        "deck_id" => deck.id,
      }

      Notes.create_note_with_card_transaction(params)
      |> Memoet.Repo.transaction()
    end)
    |> Stream.run()
  end

  defp determine_parser(filename) do
    file = File.open!(filename)
    first_line = IO.read(file, :line)
    File.close(file)

    if String.split(first_line, ";") |> Enum.count() == @columns do
        Memoet.Decks.Import.ExcelCSV
    else
        NimbleCSV.RFC4180
    end
  end
end
