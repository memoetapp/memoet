defmodule MemoetWeb.DeckController do
  use MemoetWeb, :controller

  alias Memoet.Decks
  alias Memoet.Decks.Deck
  alias Memoet.Notes
  alias Memoet.Cards
  alias Memoet.Utils.MapUtil

  # Max size 255, and " (copy)" takes 7 characters
  @title_slice_limit 248

  @spec index(Plug.Conn.t(), map) :: Plug.Conn.t()
  def index(conn, params) do
    user = Pow.Plug.current_user(conn)

    params =
      params
      |> Map.merge(%{"user_id" => user.id})

    %{entries: decks, metadata: metadata} = Decks.list_decks(params)
    render(conn, "index.html", decks: decks, metadata: metadata)
  end

  @spec public_index(Plug.Conn.t(), map) :: Plug.Conn.t()
  def public_index(conn, params) do
    %{entries: public_decks, metadata: metadata} = Decks.list_public_decks(params)
    render(conn, "public_index.html", public_decks: public_decks, metadata: metadata)
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
        |> put_status(:bad_request)
        |> render("new.html", changeset: changeset)
    end
  end

  @spec show(Plug.Conn.t(), map) :: Plug.Conn.t()
  def show(conn, %{"id" => id} = params) do
    user = Pow.Plug.current_user(conn)
    deck = Decks.get_deck!(id)

    # Redirect public deck to community route
    if deck.user_id != user.id do
      if deck.public do
        conn
        |> redirect(to: Routes.community_deck_path(conn, :public_show, deck))
      else
        conn
        |> put_flash(:error, "Invalid deck.")
        |> redirect(to: "/decks")
      end
    else
      params =
        params
        |> Map.merge(%{"deck_id" => id})

      %{entries: notes, metadata: metadata} = Notes.list_notes(params)

      conn
      |> render("show.html", deck: deck, notes: notes, metadata: metadata)
    end
  end

  @spec public_show(Plug.Conn.t(), map) :: Plug.Conn.t()
  def public_show(conn, %{"id" => id} = params) do
    deck = Decks.get_public_deck!(id)

    params =
      params
      |> Map.merge(%{"deck_id" => id})

    %{entries: notes, metadata: metadata} = Notes.list_public_notes(params)

    conn
    |> render("public_show.html", deck: deck, notes: notes, metadata: metadata)
  end

  @spec search(Plug.Conn.t(), map) :: Plug.Conn.t()
  def search(conn, params) do
    user = Pow.Plug.current_user(conn)

    params =
      params
      |> Map.merge(%{user_id: user.id})

    %{entries: notes, metadata: metadata} = Notes.list_notes(params)
    render(conn, "search.html", notes: notes, metadata: metadata)
  end

  @spec new(Plug.Conn.t(), map) :: Plug.Conn.t()
  def new(conn, _params) do
    render(conn, "new.html")
  end

  @spec edit(Plug.Conn.t(), map) :: Plug.Conn.t()
  def edit(conn, %{"id" => id} = _params) do
    user = Pow.Plug.current_user(conn)
    deck = Decks.get_deck!(id, user.id)

    render(
      conn,
      "edit.html",
      deck: deck
    )
  end

  @spec delete(Plug.Conn.t(), map) :: Plug.Conn.t()
  def delete(conn, %{"id" => id}) do
    user = Pow.Plug.current_user(conn)
    Decks.delete_deck!(id, user.id)

    conn
    |> put_flash(:info, "Delete success!")
    |> redirect(to: "/decks")
  end

  @spec clone(Plug.Conn.t(), map) :: Plug.Conn.t()
  def clone(conn, %{"id" => id}) do
    user = Pow.Plug.current_user(conn)
    deck = Decks.get_deck!(id)

    cond do
      deck.user_id == user.id ->
        conn
        |> put_flash(:error, "You already own this deck.")
        |> redirect(to: "/decks")

      not deck.public ->
        conn
        |> put_flash(:error, "The deck does not exist.")
        |> redirect(to: "/decks")

      true ->
        case Decks.get_clone_of(id, user.id) do
          %Deck{} = old_deck ->
            conn
            |> put_flash(:error, "You already copy the deck over here. Delete this first before copying again.")
            |> redirect(to: "/decks/" <> old_deck.id)

          nil ->
            conn
            |> clone_deck(deck, user)
        end
    end
  end

  defp clone_deck(conn, deck, user) do
    params =
      MapUtil.from_struct(deck)
      |> Map.merge(%{
        "name" => String.slice(deck.name, 0..@title_slice_limit) <> " (copy)",
        "user_id" => user.id,
        "public" => false,
        "source_id" => deck.id
      })

    case Decks.create_deck(params) do
      {:ok, %Deck{} = new_deck} ->
        %{from_deck_id: deck.id, to_deck_id: new_deck.id, to_user_id: user.id}
        |> Memoet.Tasks.DeckCloneJob.new()
        |> Oban.insert()

        conn
        |> put_flash(:info, "Copying deck may take a few minutes, refresh this page if necessary!")
        |> redirect(to: "/decks/" <> new_deck.id)

      {:error, _changeset} ->
        conn
        |> put_flash(:error, "Copy deck failed!")
        |> redirect(to: "/decks")
    end
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

  @spec practice(Plug.Conn.t(), map) :: Plug.Conn.t()
  def practice(conn, %{"id" => deck_id} = params) do
    user = Pow.Plug.current_user(conn)
    deck = Decks.get_deck!(deck_id, user.id)

    cards =
      case params do
        %{"note_id" => note_id} ->
          Cards.list_cards(%{"deck_id" => deck_id, "note_id" => note_id})

        _ ->
          Cards.due_cards(%{"deck_id" => deck_id})
      end

    case cards do
      [] ->
        conn
        |> render("practice.html", card: nil, deck: deck)

      [card | _] ->
        conn
        |> render("practice.html", card: card, deck: deck, intervals: Cards.next_intervals(card))
    end
  end

  @spec public_practice(Plug.Conn.t(), map) :: Plug.Conn.t()
  def public_practice(conn, %{"id" => deck_id} = params) do
    deck = Decks.get_public_deck!(deck_id)

    cards =
      case params do
        %{"note_id" => note_id} ->
          Cards.list_cards(%{"deck_id" => deck_id, "note_id" => note_id})

        _ ->
          Cards.due_cards(%{"deck_id" => deck_id, "public" => true})
      end

    case cards do
      [] ->
        conn
        |> render("public_practice.html", card: nil, deck: deck)

      [card | _] ->
        conn
        |> render("public_practice.html",
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
          "id" => deck_id,
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
        |> redirect(to: Routes.deck_path(conn, :practice, %Deck{id: deck_id}))

      {:error, _} ->
        conn
        |> put_flash(:error, "Error when answering, please try again.")
        |> redirect(
          to: Routes.deck_path(conn, :practice, %Deck{id: deck_id}, note_id: card.note_id)
        )
    end
  end

  @spec public_answer(Plug.Conn.t(), map) :: Plug.Conn.t()
  def public_answer(conn, %{"id" => deck_id} = _params) do
    conn
    |> put_flash(:error, "You are practicing in preview mode, your progress will not be saved!")
    |> redirect(to: Routes.community_deck_path(conn, :public_practice, %Deck{id: deck_id}))
  end

  @spec stats(Plug.Conn.t(), map) :: Plug.Conn.t()
  def stats(conn, %{"id" => id} = _params) do
    user = Pow.Plug.current_user(conn)
    deck = Decks.get_deck!(id, user.id)
    stats = Decks.deck_stats(id)

    conn
    |> render("stats.html", deck: deck, stats: stats)
  end

  @spec import(Plug.Conn.t(), map) :: Plug.Conn.t()
  def import(conn, %{"id" => id} = _params) do
    user = Pow.Plug.current_user(conn)
    deck = Decks.get_deck!(id, user.id)

    conn
    |> render("import.html", deck: deck)
  end

  @spec upload(Plug.Conn.t(), map) :: Plug.Conn.t()
  def upload(conn, %{"id" => id, "file" => file} = _params) do
    user = Pow.Plug.current_user(conn)
    deck = Decks.get_deck!(id, user.id)

    csv_basename = id <> "_" <> Base.url_encode64(:crypto.strong_rand_bytes(8), padding: false) <> "_import.csv"
    csv_filename = Path.join(System.tmp_dir!(), csv_basename)

    File.cp!(file.path, csv_filename)
    Decks.import_notes(deck, csv_filename)

    conn
    |> put_flash(:info, "Import process is started, you may need to refresh the deck later.")
    |> redirect(to: "/decks/" <> id)
  end
end
