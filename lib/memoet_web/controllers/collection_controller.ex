defmodule MemoetWeb.CollectionController do
  use MemoetWeb, :controller

  alias Memoet.{Collections, Collections.Collection, Cards, Decks}

  @spec edit(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def edit(conn, _params) do
    user = Pow.Plug.current_user(conn)
    collection = Collections.get_today_collection(user.id)
    changeset = Collection.changeset(collection, %{})

    %{entries: decks} = Decks.list_decks(%{"user_id" => user.id, "limit" => 5})

    render(
      conn,
      "edit.html",
      decks: decks,
      collection: collection,
      changeset: changeset
    )
  end

  @spec update(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def update(conn, %{"collection" => collection_data} = _params) do
    user = Pow.Plug.current_user(conn)
    params = Map.merge(collection_data, %{"user_id" => user.id})

    case Collections.update_today_collection(user.id, params) do
      {:ok, _collection} ->
        conn
        |> put_flash(:info, "Update collection success!")
        |> redirect(to: Routes.today_path(conn, :edit))

      {:error, changeset} ->
        collection = Collections.get_today_collection(user.id)

        conn
        |> put_flash(:error, "Fail to update collection!")
        |> render("edit.html", collection: collection, changeset: changeset)
    end
  end

  @spec practice(Plug.Conn.t(), map) :: Plug.Conn.t()
  def practice(conn, %{"id" => collection_id} = params) do
    user = Pow.Plug.current_user(conn)
    decks = Collections.get_decks(collection_id, user.id)
    cards = Cards.due_cards(decks, params)

    case cards do
      [] ->
        conn
        |> render("practice.html", card: nil, deck: nil)

      [card | _] ->
        deck = Decks.get_deck!(card.deck_id)
        conn
        |> assign(:page_title, card.note.title <> " · " <> deck.name)
        |> render("practice.html", card: card, deck: deck, intervals: Cards.next_intervals(card))
    end
  end

  @spec answer(Plug.Conn.t(), map) :: Plug.Conn.t()
  def answer(
        conn,
        %{
          "id" => _collection_id,
          "card_id" => card_id,
          "answer" => choice,
          "visit_time" => visit_time
        } = _params
      ) do
    user = Pow.Plug.current_user(conn)
    card = Cards.get_card!(card_id, user.id)

    now = :os.system_time(:millisecond)
    {visit_time, _} = Integer.parse(to_string(visit_time))
    time_answer = now - visit_time

    case Cards.answer_card(card, choice, time_answer) do
      {:ok, _} ->
        conn
        |> redirect(to: Routes.today_path(conn, :practice))

      {:error, _} ->
        conn
        |> put_flash(:error, "Error when answering, please try again.")
        |> redirect(to: Routes.today_path(conn, :practice))
    end
  end
end
