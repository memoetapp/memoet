defmodule MemoetWeb.DeckAPIController do
  use MemoetWeb, :controller

  alias Ecto.Changeset
  alias Memoet.Decks
  alias Memoet.Decks.Deck
  alias Memoet.Cards
  alias Memoet.Cards.Card
  alias MemoetWeb.ErrorHelpers

  @spec index(Plug.Conn.t(), map) :: Plug.Conn.t()
  def index(conn, params) do
    user = Pow.Plug.current_user(conn)

    params =
      params
      |> Map.merge(%{"user_id" => user.id})

    %{entries: decks, metadata: metadata} = Decks.list_decks(params)

    conn
    |> render("index.json", decks: decks, metadata: metadata)
  end

  @spec create(Plug.Conn.t(), map) :: Plug.Conn.t()
  def create(conn, deck_params) do
    user = Pow.Plug.current_user(conn)

    params =
      deck_params
      |> Map.merge(%{
        "user_id" => user.id
      })

    case Decks.create_deck(params) do
      {:ok, %Deck{} = deck} ->
        conn
        |> render("create.json", deck: deck)

      {:error, changeset} ->
        errors = Changeset.traverse_errors(changeset, &ErrorHelpers.translate_error/1)

        conn
        |> put_status(400)
        |> json(%{error: %{status: 400, message: "Couldn't create deck", errors: errors}})
    end
  end

  @spec show(Plug.Conn.t(), map) :: Plug.Conn.t()
  def show(conn, %{"id" => id} = _params) do
    user = Pow.Plug.current_user(conn)
    deck = Decks.get_deck!(id, user.id)

    conn
    |> render("show.json", deck: deck)
  end

  @spec delete(Plug.Conn.t(), map) :: Plug.Conn.t()
  def delete(conn, %{"id" => id}) do
    user = Pow.Plug.current_user(conn)
    Decks.delete_deck!(id, user.id)

    conn
    |> send_resp(:no_content, "")
  end

  @spec update(Plug.Conn.t(), map) :: Plug.Conn.t()
  def update(conn, %{"id" => id} = deck_params) do
    user = Pow.Plug.current_user(conn)
    deck = Decks.get_deck!(id, user.id)

    case Decks.update_deck(deck, deck_params) do
      {:ok, %Deck{} = deck} ->
        conn
        |> render("update.json", deck: deck)

      {:error, changeset} ->
        errors = Changeset.traverse_errors(changeset, &ErrorHelpers.translate_error/1)

        conn
        |> put_status(400)
        |> json(%{error: %{status: 400, message: "Couldn't update deck", errors: errors}})
    end
  end

  @spec practice(Plug.Conn.t(), map) :: Plug.Conn.t()
  def practice(conn, %{"id" => deck_id} = params) do
    user = Pow.Plug.current_user(conn)
    deck = Decks.get_deck!(deck_id, user.id)

    cards =
      case params do
        %{"note_id" => note_id} ->
          Cards.list_cards(%{"deck_id" => deck.id, "note_id" => note_id})

        _ ->
          Cards.due_cards(%{"deck_id" => deck.id, "learning_order" => deck.learning_order})
      end

    case cards do
      [] ->
        conn
        |> render("practice.json", card: nil)

      [card | _] ->
        conn
        |> render("practice.json", card: card)
    end
  end

  @spec answer(Plug.Conn.t(), map) :: Plug.Conn.t()
  def answer(
        conn,
        %{"card_id" => card_id, "answer" => choice, "time_answer" => time_answer} = _params
      ) do
    user = Pow.Plug.current_user(conn)
    card = Cards.get_card!(card_id, user.id)

    case Cards.answer_card(card, choice, time_answer) do
      {:ok, %Card{} = card} ->
        conn
        |> render("practice.json", card: card)

      {:error, changeset} ->
        errors = Changeset.traverse_errors(changeset, &ErrorHelpers.translate_error/1)

        conn
        |> put_status(400)
        |> json(%{error: %{status: 400, message: "Couldn't save answer", errors: errors}})
    end
  end
end
