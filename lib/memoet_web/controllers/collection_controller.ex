defmodule MemoetWeb.CollectionController do
  use MemoetWeb, :controller

  alias Memoet.{Collections, Collections.Collection, Cards, Decks}
  alias Memoet.Str

  @decks_limit 20

  @spec edit(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def edit(conn, _params) do
    user = Pow.Plug.current_user(conn)
    collection = Collections.get_today_collection(user.id)
    changeset = Collection.changeset(collection, %{})

    current_decks =
      collection.decks
      |> Enum.map(fn d -> d.id end)
      |> MapSet.new()

    %{entries: recent_decks} = Decks.list_decks(%{"user_id" => user.id, "limit" => @decks_limit})

    render(
      conn,
      "edit.html",
      recent_decks: recent_decks,
      current_decks: current_decks,
      collection: collection,
      deck_limit: @decks_limit,
      changeset: changeset
    )
  end

  @spec update(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def update(conn, %{"collection" => collection_data} = _params) do
    user = Pow.Plug.current_user(conn)
    collection = Collections.get_today_collection(user.id)

    decks_collections =
      case collection_data do
        %{"deck_ids" => deck_ids} ->
          deck_ids
          |> Enum.map(fn id ->
            %{
              "deck_id" => id,
              "collection_id" => collection.id,
              "user_id" => user.id
            }
          end)

        _ ->
          []
      end

    params =
      Map.merge(
        collection_data,
        %{
          "user_id" => user.id,
          "decks_collections" => decks_collections
        }
      )

    case Collections.update_today_collection(collection, params) do
      {:ok, _collection} ->
        conn
        |> put_flash(:info, "Update " <> collection.name <> " collection success!")
        |> redirect(to: "/")

      {:error, changeset} ->
        conn
        |> put_flash(:error, StringUtil.changeset_error_to_string(changeset))
        |> redirect(to: Routes.today_path(conn, :edit))
    end
  end

  @spec practice(Plug.Conn.t(), map) :: Plug.Conn.t()
  def practice(conn, _params) do
    user = Pow.Plug.current_user(conn)
    today_collection = Collections.get_today_collection(user.id)
    decks = today_collection.decks
    cards = Cards.due_cards(user, decks)

    case cards do
      [] ->
        conn
        |> render("practice.html", card: nil, deck: nil)

      [card | _] ->
        deck =
          decks
          |> Enum.filter(fn d -> d.id == card.deck_id end)
          |> List.first()

        conn
        |> assign(:page_title, card.note.title <> " · " <> deck.name)
        |> render(
          "practice.html",
          card: card,
          deck: deck,
          intervals: Cards.next_intervals(card)
        )
    end
  end

  @spec answer(Plug.Conn.t(), map) :: Plug.Conn.t()
  def answer(
        conn,
        %{
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
