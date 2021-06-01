NimbleCSV.define(Memoet.Decks.Import.ExcelCSV,
  separator: ";",
  escape: "\"",
  line_separator: "\r\n",
  moduledoc: false
)

defmodule Memoet.Decks.Import do
  @moduledoc """
  Import notes to deck and notify client in the same time
  """

  import MemoetWeb.Gettext

  require Logger
  require Sentry

  alias Memoet.Repo
  alias Memoet.Notes
  alias Memoet.Notes.Types
  alias Memoet.Str
  alias Memoet.Decks.ImportError

  # [title, image, content, type, op1, op2, op3, op4, op5, correct_op, hint]
  @columns 11

  def import_csv(deck, filename, opts) do
    notify_pid = Keyword.get(opts, :notify, self())

    Repo.transaction(
      fn ->
        try do
          import_csv!(deck, filename, notify_pid)
        rescue
          e ->
            Logger.error(e)
            Sentry.capture_exception(e, stacktrace: __STACKTRACE__, extra: %{deck_id: deck.id})
            Repo.rollback(e)
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

  defp import_csv!(deck, filename, notify_pid) do
    parser = determine_parser(filename)

    lines =
      File.stream!(filename)
      |> parser.parse_stream()
      |> Enum.count()

    send(notify_pid, {:notes_import_progress, 0, lines})

    File.stream!(filename)
    |> parser.parse_stream()
    |> Stream.map(fn [title, image, content, type, op1, op2, op3, op4, op5, correct_op, hint] ->
      %{
        "title" => if(Str.blank?(title), do: "No title", else: title),
        "image" => image,
        "content" => content,
        "type" => Types.detect(type),
        "options" => [
          %{"content" => op1, "correct" => correct_op == "1"},
          %{"content" => op2, "correct" => correct_op == "2"},
          %{"content" => op3, "correct" => correct_op == "3"},
          %{"content" => op4, "correct" => correct_op == "4"},
          %{"content" => op5, "correct" => correct_op == "5"}
        ],
        "hint" => hint,
        "user_id" => deck.user_id,
        "deck_id" => deck.id
      }
    end)
    |> Stream.with_index()
    |> Stream.map(fn {params, n} ->
      Notes.create_note_with_card_transaction(params)
      |> Memoet.Repo.transaction()
      |> case do
        {:ok, _} -> n
        {:error, _op, changeset, _changes} -> raise_import_error!(changeset, n + 1)
      end
    end)
    |> Stream.chunk_every(100)
    |> Enum.each(fn ns ->
      send(notify_pid, {:notes_import_progress, List.last(ns) + 1, lines})
    end)
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

  defp raise_import_error!(changeset, line) do
    message =
      case changeset.errors do
        [{field, {message, _}} | _] ->
          gettext("Field %{field}: %{message}", field: field, message: message)

        _other ->
          gettext("Unknown data error")
      end

    raise ImportError,
      message:
        gettext("Error importing note in line %{line}: %{message}",
          line: line,
          message: message
        ),
      line: line
  end
end
