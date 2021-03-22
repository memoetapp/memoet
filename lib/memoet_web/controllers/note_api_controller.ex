defmodule MemoetWeb.NoteAPIController do
  use MemoetWeb, :controller

  alias Ecto.Changeset
  alias Memoet.Notes
  alias Memoet.Notes.Note
  alias MemoetWeb.ErrorHelpers

  @spec create(Plug.Conn.t(), map) :: Plug.Conn.t()
  def create(conn, %{"deck_api_id" => deck_id, "note" => note_params} = _params) do
    user = Pow.Plug.current_user(conn)

    params =
      note_params
      |> Map.merge(%{
        "deck_id" => deck_id,
        "user_id" => user.id
      })

    Notes.create_note_with_card_transaction(params)
    |> Memoet.Repo.transaction()
    |> case do
      {:ok, %{note: note}} ->
        conn
        |> render("create.json", note: note)

      {:error, _op, changeset, _changes} ->
        errors = Changeset.traverse_errors(changeset, &ErrorHelpers.translate_error/1)

        conn
        |> put_status(400)
        |> json(%{error: %{status: 400, message: "Couldn't create note", errors: errors}})
    end
  end

  @spec index(Plug.Conn.t(), map) :: Plug.Conn.t()
  def index(conn, %{"deck_api_id" => deck_id} = params) do
    params =
      params
      |> Map.merge(%{"deck_id" => deck_id})

    %{entries: notes, metadata: metadata} = Notes.list_notes(params)

    conn
    |> render("index.json", notes: notes, metadata: metadata)
  end

  @spec show(Plug.Conn.t(), map) :: Plug.Conn.t()
  def show(conn, %{"id" => id}) do
    user = Pow.Plug.current_user(conn)
    note = Notes.get_note!(id, user.id)

    conn
    |> render("show.json", note: note)
  end

  @spec delete(Plug.Conn.t(), map) :: Plug.Conn.t()
  def delete(conn, %{"id" => id}) do
    user = Pow.Plug.current_user(conn)
    Notes.delete_note!(id, user.id)

    conn
    |> send_resp(:no_content, "")
  end

  @spec update(Plug.Conn.t(), map) :: Plug.Conn.t()
  def update(conn, %{"id" => id, "note" => note_params} = _params) do
    user = Pow.Plug.current_user(conn)
    note = Notes.get_note!(id, user.id)

    case Notes.update_note(note, note_params) do
      {:ok, %Note{} = note} ->
        conn
        |> render("update.json", note: note)

      {:error, changeset} ->
        errors = Changeset.traverse_errors(changeset, &ErrorHelpers.translate_error/1)

        conn
        |> put_status(400)
        |> json(%{error: %{status: 400, message: "Couldn't update note", errors: errors}})
    end
  end
end
