defmodule MemoetWeb.DeckController do
  use MemoetWeb, :controller

  alias Memoet.Decks
  alias Memoet.Decks.Deck
  alias Memoet.Utils.StringUtil

  plug :put_layout, "deck.html"

  @spec index(Plug.Conn.t(), map) :: Plug.Conn.t()
  def index(conn, params) do
    user = Pow.Plug.current_user(conn)
    decks = Decks.list_decks(user.id, params)
    render(conn, "index.html", decks: decks)
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
        |> put_flash(:error, StringUtil.changeset_error_to_string(changeset))
        |> redirect(to: "/decks")
    end
  end

  @spec show(Plug.Conn.t(), map) :: Plug.Conn.t()
  def show(conn, %{"id" => id}) do
    user = Pow.Plug.current_user(conn)
    deck = Decks.get_deck!(id, user.id)
    render(conn, "show.html", deck: deck)
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
        |> put_flash(:error, StringUtil.changeset_error_to_string(changeset))
        |> redirect(to: "/decks/" <> deck.id)
    end
  end
end
