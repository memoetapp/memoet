defmodule MemoetWeb.DeckController do
  use MemoetWeb, :controller

  alias Memoet.Decks
  alias Memoet.Decks.Deck
  alias Memoet.Notes
  alias Memoet.Notes.Types
  alias Memoet.Cards

  @spec index(Plug.Conn.t(), map) :: Plug.Conn.t()
  def index(conn, _params) do
    user = Pow.Plug.current_user(conn)
    decks = Decks.list_decks(%{"user_id" => user.id})
    public_decks = Decks.list_decks(%{"public" => true})
    render(conn, "index.html", decks: decks, public_decks: public_decks)
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
        |> put_flash(:info, "Create deck \"" <> deck.name <> "\" success!")
        |> redirect(to: "/decks/" <> deck.id)

      {:error, changeset} ->
        conn
        |> render("new.html", changeset: changeset)
    end
  end

  @spec show(Plug.Conn.t(), map) :: Plug.Conn.t()
  def show(conn, %{"id" => id}) do
    user = Pow.Plug.current_user(conn)
    deck = Decks.get_deck!(id)

    if deck.user_id != user.id and not deck.public do
      redirect(conn, to: "/decks")
    else
      notes = Notes.list_notes(deck.id, %{})
      render(conn, "show.html", deck: deck, notes: notes)
    end
  end

  @spec new(Plug.Conn.t(), map) :: Plug.Conn.t()
  def new(conn, _params) do
    render(conn, "new.html")
  end

  @spec edit(Plug.Conn.t(), map) :: Plug.Conn.t()
  def edit(conn, %{"id" => id}) do
    user = Pow.Plug.current_user(conn)
    deck = Decks.get_deck!(id, user.id)
    render(conn, "edit.html", deck: deck)
  end

  @spec update(Plug.Conn.t(), map) :: Plug.Conn.t()
  def update(conn, %{"id" => id} = deck_params) do
    user = Pow.Plug.current_user(conn)
    deck = Decks.get_deck!(id, user.id)

    case Decks.update_deck(deck, deck_params) do
      {:ok, %Deck{} = deck} ->
        conn
        |> put_flash(:info, "Update deck success!")
        |> redirect(to: "/decks/" <> deck.id)

      {:error, changeset} ->
        conn
        |> render("edit.html", changeset: changeset)
    end
  end

  @spec due(Plug.Conn.t(), map) :: Plug.Conn.t()
  def due(conn, %{"id" => deck_id} = _params) do
    user = Pow.Plug.current_user(conn)
    deck = Decks.get_deck!(deck_id, user.id)
    due_cards = Cards.due_cards(user.id, %{deck_id: deck_id})

    case due_cards do
      [] ->
        conn
        |> render("review.html", card: nil, deck: deck)

      [card | _] ->
        conn
        |> render("review.html", card: card, deck: deck)
    end
  end

  @spec review(Plug.Conn.t(), map) :: Plug.Conn.t()
  def review(conn, %{"id" => _deck_id, "card_id" => card_id, "answer" => choice} = _params) do
    user = Pow.Plug.current_user(conn)
    card = Cards.get_card!(card_id, user.id)

    Cards.answer_card(card, choice)

    conn
    |> redirect(to: Routes.review_card_path(conn, :due, %Deck{id: card.deck_id}))
  end
end
