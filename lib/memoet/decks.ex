defmodule Memoet.Decks do
  @moduledoc """
  Decks service
  """

  import Ecto.Query
  require Logger

  alias Memoet.Repo
  alias Memoet.Decks.{Deck, Import}
  alias Memoet.Cards.{Card, CardLog}
  alias Memoet.Notes
  alias Memoet.Utils.{MapUtil, RequestUtil, TimestampUtil}

  @stats_days 20

  @spec list_decks(map) :: map()
  def list_decks(params \\ %{}) do
    {cursor_before, cursor_after, limit} = RequestUtil.get_pagination_params(params)

    Deck
    |> where(^filter_where(params))
    |> order_by(desc: :updated_at)
    |> Repo.paginate(
      before: cursor_before,
      after: cursor_after,
      include_total_count: true,
      cursor_fields: [{:updated_at, :desc}],
      limit: limit
    )
  end

  @spec list_public_decks(map) :: map()
  def list_public_decks(params \\ %{}) do
    {cursor_before, cursor_after, limit} = RequestUtil.get_pagination_params(params)

    params =
      params
      |> Map.merge(%{"public" => true, "source_id" => nil, "listed" => true})

    Deck
    |> where(^filter_where(params))
    |> order_by(desc: :inserted_at)
    |> Repo.paginate(
      before: cursor_before,
      after: cursor_after,
      include_total_count: true,
      cursor_fields: [{:inserted_at, :desc}],
      limit: limit
    )
  end

  @spec get_deck!(binary()) :: Deck.t()
  def get_deck!(id) do
    Deck
    |> Repo.get_by!(id: id)
  end

  @spec get_public_deck!(binary()) :: Deck.t()
  def get_public_deck!(id) do
    Deck
    |> Repo.get_by!(id: id, public: true)
  end

  def get_clone_of(deck_id, user_id) do
    clones =
      Deck
      |> where(^filter_where(%{"source_id" => deck_id, "user_id" => user_id}))
      |> limit(1)
      |> Repo.all()

    case clones do
      [item] -> item
      _ -> nil
    end
  end

  def touch_deck_update_time(id) do
    Repo.update_all(
      from(d in Deck, where: d.id == ^id),
      set: [updated_at: Timex.now()]
    )
  end

  @spec delete_deck!(binary(), binary()) :: Deck.t()
  def delete_deck!(id, user_id) do
    Deck
    |> Repo.get_by!(id: id, user_id: user_id)
    |> Repo.delete!()
  end

  @spec get_deck!(binary(), binary()) :: Deck.t()
  def get_deck!(id, user_id) do
    Deck
    |> Repo.get_by!(id: id, user_id: user_id)
  end

  @spec create_deck(map()) :: {:ok, Deck.t()} | {:error, Ecto.Changeset.t()}
  def create_deck(attrs \\ %{}) do
    %Deck{}
    |> Deck.changeset(attrs)
    |> Repo.insert()
  end

  @spec update_deck(Deck.t(), map()) :: {:ok, Deck.t()} | {:error, Ecto.Changeset.t()}
  def update_deck(%Deck{} = deck, attrs) do
    new_per_day = case attrs do
      %{"new_per_day" => new_per_day} -> new_per_day
      _ -> deck.new_per_day
    end

    new_per_day = case Integer.parse(to_string(new_per_day)) do
      {c, _} -> c
      :error -> 20
    end

    attrs = if new_per_day != deck.new_per_day do
      new_to_learn = new_per_day - deck.new_per_day
      new_today = max(deck.new_today + new_to_learn, 0)

      attrs
      |> Map.merge(%{"new_today" => new_today})
    else
      attrs
    end

    deck
    |> Deck.changeset(attrs)
    |> Repo.update()
  end

  @spec update_new(Deck.t(), map()) :: {:ok, Deck.t()} | {:error, Ecto.Changeset.t()}
  def update_new(%Deck{} = deck, attrs) do
    deck
    |> Deck.new_changeset(attrs)
    |> Repo.update()
  end

  @spec filter_where(map) :: Ecto.Query.DynamicExpr.t()
  defp filter_where(attrs) do
    Enum.reduce(attrs, dynamic(true), fn
      {"user_id", value}, dynamic ->
        dynamic([d], ^dynamic and d.user_id == ^value)

      {"public", value}, dynamic ->
        dynamic([d], ^dynamic and d.public == ^value)

      {"listed", value}, dynamic ->
        dynamic([d], ^dynamic and d.listed == ^value)

      {"source_id", nil}, dynamic ->
        dynamic([d], ^dynamic and is_nil(d.source_id))

      {"source_id", value}, dynamic ->
        dynamic([d], ^dynamic and d.source_id == ^value)

      {"q", value}, dynamic ->
        q = "%" <> value <> "%"
        dynamic([d], ^dynamic and ilike(d.name, ^q))

      {_, _}, dynamic ->
        # Not a where parameter
        dynamic
    end)
  end

  def clone_notes(from_deck_id, to_deck_id, to_user_id) do
    Repo.transaction(
      fn ->
        Notes.stream_notes(from_deck_id)
        |> Stream.map(fn note ->
          params =
            MapUtil.from_struct(note)
            |> Map.merge(%{
              "options" => Enum.map(note.options, fn o -> MapUtil.from_struct(o) end),
              "deck_id" => to_deck_id,
              "user_id" => to_user_id
            })

          Notes.create_note_with_card_transaction(params)
          |> Memoet.Repo.transaction()
        end)
        |> Stream.run()
      end,
      timeout: :infinity
    )
  end

  @spec deck_stats(binary(), String.t()) :: map()
  def deck_stats(deck_id, timezone) do
    now = Timex.now(timezone)
          |> Timex.end_of_day()
    today_unix = TimestampUtil.days_from_epoch(timezone)

    from_date = DateTime.add(now, -@stats_days * 86_400, :second)
    to_date = DateTime.add(now, @stats_days * 86_400, :second)

    practices = practice_by_date(deck_id, from_date, to_date)

    %{
      counter_to_date: counter_to_date(deck_id),
      span_data: %{
        due_by_date: due_by_date(deck_id, from_date, to_date, today_unix),
        practice_by_date: practices.count,
        speed_by_date: practices.speed,
        answer_by_choice: answer_by_choice(deck_id, from_date, to_date)
      },
      span_time: %{
        timezone: timezone,
        from_date: DateTime.to_date(from_date),
        to_date: DateTime.to_date(to_date)
      }
    }
  end

  @spec counter_to_date(binary()) :: map()
  def counter_to_date(deck_id) do
    counts =
      from(c in Card,
        group_by: c.card_queue,
        where: c.deck_id == ^deck_id,
        select: {c.card_queue, count(c.id)}
      )
      |> Repo.all()

    counts =
      counts
      |> Enum.map(fn {q, c} -> {q, c} end)
      |> Enum.into(%{})

    total =
      counts
      |> Enum.map(fn {_q, c} -> c end)
      |> Enum.sum()

    counts
    |> Map.merge(%{total: total})
  end

  @spec due_by_date(binary(), DateTime.t(), DateTime.t(), integer()) :: map()
  def due_by_date(deck_id, from_date, to_date, today_unix) do
    from_date = Date.diff(from_date, ~D[1970-01-01])
    to_date = Date.diff(to_date, ~D[1970-01-01])

    from(c in Card,
      group_by: c.due,
      # review, day_learn only
      where:
        c.deck_id == ^deck_id and
          c.due >= ^from_date and
          c.due <= ^to_date and
          c.card_queue in [2, 3],
      order_by: c.due,
      select: {c.due, count(c.id)}
    )
    |> Repo.all()
    |> Enum.map(fn {d, c} -> {d - today_unix, c} end)
    |> Enum.into(%{})
  end

  @spec practice_by_date(binary(), DateTime.t(), DateTime.t()) :: map()
  def practice_by_date(deck_id, from_date, to_date) do
    today_date = Date.utc_today()

    practices =
      from(c in CardLog,
        group_by: fragment("created_date"),
        where:
          c.deck_id == ^deck_id and
            c.inserted_at >= ^from_date and
            c.inserted_at <= ^to_date,
        select:
          {fragment("date(?) as created_date", c.inserted_at),
           fragment("round(avg(?))", c.time_answer), count(c.id)}
      )
      |> Repo.all()
      |> Enum.map(fn {d, s, c} -> {Date.diff(d, today_date), s, c} end)

    %{
      count:
        practices
        |> Enum.map(fn {d, _, c} -> {d, c} end)
        |> Enum.into(%{}),
      speed:
        practices
        |> Enum.map(fn {d, s, _} ->
          {d, s |> Decimal.div(1_000) |> Decimal.round(1) |> Decimal.to_float()}
        end)
        |> Enum.into(%{})
    }
  end

  @spec answer_by_choice(binary(), DateTime.t(), DateTime.t()) :: map()
  def answer_by_choice(deck_id, from_date, to_date) do
    from(c in CardLog,
      group_by: c.choice,
      where:
        c.deck_id == ^deck_id and
          c.inserted_at >= ^from_date and
          c.inserted_at <= ^to_date,
      select: {c.choice, count(c.id)}
    )
    |> Repo.all()
    |> Enum.into(%{})
  end

  def import_notes(deck, file) do
    Task.start(fn ->
      Import.import_csv(deck, file)
    end)
  end
end
