defmodule MemoetWeb.ImportNotesLive do
  @moduledoc """
  Upload notes from csv file
  """

  use MemoetWeb, :live_view
  require Logger
  alias Memoet.Decks
  alias Memoet.Decks.ImportError

  @impl true
  def mount(_params, session, socket) do
    socket =
      socket
      |> allow_upload(:csv, accept: [".csv", ".txt", ".tsv"], max_entries: 1)
      |> assign(:uploaded_files, [])
      |> assign(:deck_id, session["deck_id"])
      |> put_default_assigns()

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    Phoenix.View.render(MemoetWeb.NoteView, "import_live.html", assigns)
  end

  @impl true
  def handle_event("validate", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("import", _params, socket) do
    [{csv_filename, import_task}] =
      consume_uploaded_entries(socket, :csv, fn %{path: upload_path}, _entry ->
        pid = self()

        deck = Decks.get_deck!(socket.assigns.deck_id)

        random_name = Base.url_encode64(:crypto.strong_rand_bytes(8), padding: false)
        csv_basename = deck.id <> "_" <> random_name <> "_import.csv"

        csv_filename = Path.join(System.tmp_dir!(), csv_basename)
        File.cp!(upload_path, csv_filename)

        task =
          Task.async(fn ->
            Memoet.Decks.Import.import_csv(
              deck,
              csv_filename,
              notify: pid
            )
          end)

        {csv_filename, task}
      end)

    socket =
      socket
      |> assign(:csv_filename, csv_filename)
      |> assign(:import_task, import_task)
      |> put_default_assigns()

    {:noreply, socket}
  end

  @impl true
  def handle_info({:notes_import_progress, progress, total}, socket) do
    socket =
      socket
      |> assign(:import_progress, progress)
      |> assign(:import_total, total)

    {:noreply, socket}
  end

  def handle_info({reference, {:error, reason}}, socket) when is_reference(reference) do
    File.rm(socket.assigns.csv_filename)

    case reason do
      %ImportError{} ->
        {:noreply, assign(socket, :import_error, reason)}

      _ ->
        {:noreply, assign(socket, :import_error, %ImportError{message: "File format error!"})}
    end
  end

  def handle_info({reference, :ok}, socket) when is_reference(reference) do
    File.rm(socket.assigns.csv_filename)

    {:noreply, socket}
  end

  def handle_info({:DOWN, reference, :process, _, :normal}, socket)
      when is_reference(reference) do
    File.rm(socket.assigns.csv_filename)

    {:noreply, socket}
  end

  @impl true
  def terminate(:normal, socket) do
    if socket.assigns.csv_filename do
      File.rm(socket.assigns.csv_filename)
    end
  end

  @impl true
  def terminate(_, _) do
    # Catch all other terminate cases
  end

  defp put_default_assigns(socket) do
    socket
    |> assign(:import_progress, 0)
    |> assign(:import_total, 0)
    |> assign(:import_error, nil)
  end
end
