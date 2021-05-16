defmodule Memoet.Cards do
  @moduledoc """
  Card context
  """
  import Ecto.Query

  require Logger

  alias Memoet.Cards.{Card, CardLog, CardTypes, CardQueues, Choices}
  alias Memoet.{Decks, Users, SRS, Repo}
  alias Memoet.Utils.TimestampUtil

  @limit 1
  # 1 sec
  @min_time_answer 1_000
  # 60 secs
  @max_time_answer 60_000

  def due_cards(user, deck) do
    config = Users.get_srs_config(user.id)
    now = TimestampUtil.now()
    today = TimestampUtil.days_from_epoch(config.timezone)
    collapse_time = config.learn_ahead_time * 60

    # Due cards order:
    # 1. Learn cards
    # 2. Day learn cards
    # 3. Review cards
    # 4. New cards
    # 5. Collapsed learn cards

    # 1
    cards = get_some_cards(get_learn_cards_query(now), deck.id)

    if length(cards) > 0 do
      cards
    else
      # 2
      cards = get_some_cards(get_day_learn_cards_query(today), deck.id)

      if length(cards) > 0 do
        cards
      else
        # 3
        cards = get_some_cards(get_review_cards_query(today), deck.id)

        if length(cards) > 0 do
          cards
        else
          # 4
          new_today = get_deck_new_today(deck, today)

          cards =
            if new_today > 0 do
              get_some_cards(get_new_cards_query(deck.learning_order), deck.id)
            else
              cards
            end

          if length(cards) > 0 do
            cards
          else
            # 5
            get_some_cards(get_learn_cards_query(now + collapse_time), deck.id)
          end
        end
      end
    end
  end

  def count_today(deck) do
    config = Users.get_srs_config(deck.user_id)
    now = TimestampUtil.now()
    today = TimestampUtil.days_from_epoch(config.timezone)

    new_today = get_deck_new_today(deck, today)

    due_today =
      from(c in Card,
        where:
          ((c.card_queue == ^CardQueues.learn() and c.due < ^now) or
             (c.card_queue == ^CardQueues.day_learn() and c.due <= ^today) or
             (c.card_queue == ^CardQueues.review() and c.due <= ^today)) and
            c.deck_id == ^deck.id
      )
      |> Repo.aggregate(:count)

    %{
      new: new_today,
      due: due_today
    }
  end

  defp get_deck_new_today(deck, today) do
    if deck.day_today < today do
      new_remain = count_new_cards(deck.id)
      deck_new_today = min(deck.new_per_day, new_remain)
      Decks.update_new(deck, %{"new_today" => deck_new_today, "day_today" => today})
      deck_new_today
    else
      deck.new_today
    end
  end

  defp count_new_cards(deck_id) do
    from(c in Card,
      where: c.card_queue == ^CardQueues.new() and c.deck_id == ^deck_id
    )
    |> Repo.aggregate(:count)
  end

  defp get_some_cards(query, deck_id) do
    query
    |> where(^filter_where(%{"deck_id" => deck_id}))
    |> limit(@limit)
    |> Repo.all()
    |> Repo.preload([:note])
  end

  defp get_learn_cards_query(now) do
    from(c in Card,
      where: c.card_queue == ^CardQueues.learn() and c.due < ^now,
      order_by: fragment("RANDOM()")
    )
  end

  defp get_day_learn_cards_query(today) do
    from(c in Card,
      where: c.card_queue == ^CardQueues.day_learn() and c.due <= ^today,
      order_by: fragment("RANDOM()")
    )
  end

  defp get_review_cards_query(today) do
    from(c in Card,
      where: c.card_queue == ^CardQueues.review() and c.due <= ^today,
      order_by: fragment("RANDOM()")
    )
  end

  defp get_new_cards_query(learning_order) do
    case learning_order do
      "first_created" ->
        from(c in Card,
          where: c.card_queue == ^CardQueues.new(),
          order_by: c.inserted_at
        )

      _ ->
        from(c in Card,
          where: c.card_queue == ^CardQueues.new(),
          order_by: fragment("RANDOM()")
        )
    end
  end

  @spec list_cards(map) :: [Card.t()]
  def list_cards(params) do
    Card
    |> where(^filter_where(params))
    |> limit(@limit)
    |> order_by(fragment("RANDOM()"))
    |> Repo.all()
    |> Repo.preload([:note])
  end

  @spec get_card!(binary()) :: Card.t() | nil
  def get_card!(id) do
    Card
    |> Repo.get!(id)
    |> Repo.preload([:note])
  end

  @spec get_card!(binary(), binary()) :: Card.t() | nil
  def get_card!(id, user_id) do
    Card
    |> Repo.get_by!(id: id, user_id: user_id)
    |> Repo.preload([:note])
  end

  @spec create_card(map()) :: {:ok, Card.t()} | {:error, Ecto.Changeset.t()}
  def create_card(attrs \\ %{}) do
    %Card{}
    |> Card.changeset(attrs)
    |> Repo.insert()
  end

  @spec update_card(Card.t(), map()) :: {:ok, Card.t()} | {:error, Ecto.Changeset.t()}
  def update_card(%Card{} = card, attrs) do
    card
    |> Card.changeset(attrs)
    |> Repo.update()
  end

  @spec bury_card(Card.t()) :: {:ok, Card.t()} | {:error, Ecto.Changeset.t()}
  defp bury_card(%Card{} = card) do
    scheduler = SRS.get_scheduler(card.user_id)

    srs_card =
      SRS.Card.from_ecto_card(card)
      |> SRS.Sm2.bury_card(scheduler)

    ecto_card = Map.from_struct(SRS.Card.to_ecto_card(srs_card))

    card
    |> Card.srs_changeset(ecto_card)
    |> Repo.update()
  end

  @spec unbury_card(Card.t()) :: {:ok, Card.t()} | {:error, Ecto.Changeset.t()}
  defp unbury_card(%Card{} = card) do
    scheduler = SRS.get_scheduler(card.user_id)

    srs_card =
      SRS.Card.from_ecto_card(card)
      |> SRS.Sm2.unbury_card(scheduler)

    ecto_card = Map.from_struct(SRS.Card.to_ecto_card(srs_card))

    card
    |> Card.srs_changeset(ecto_card)
    |> Repo.update()
  end

  @spec suspend_card(Card.t()) :: {:ok, Card.t()} | {:error, Ecto.Changeset.t()}
  defp suspend_card(%Card{} = card) do
    scheduler = SRS.get_scheduler(card.user_id)

    srs_card =
      SRS.Card.from_ecto_card(card)
      |> SRS.Sm2.suspend_card(scheduler)

    ecto_card = Map.from_struct(SRS.Card.to_ecto_card(srs_card))

    card
    |> Card.srs_changeset(ecto_card)
    |> Repo.update()
  end

  @spec unsuspend_card(Card.t()) :: {:ok, Card.t()} | {:error, Ecto.Changeset.t()}
  defp unsuspend_card(%Card{} = card) do
    scheduler = SRS.get_scheduler(card.user_id)

    srs_card =
      SRS.Card.from_ecto_card(card)
      |> SRS.Sm2.unsuspend_card(scheduler)

    ecto_card = Map.from_struct(SRS.Card.to_ecto_card(srs_card))

    card
    |> Card.srs_changeset(ecto_card)
    |> Repo.update()
  end

  @spec action_card(Card.t(), map()) :: {:ok, Card.t()} | {:error, Ecto.Changeset.t()}
  def action_card(%Card{} = card, action) do
    case action do
      "suspend" -> suspend_card(card)
      "unsuspend" -> unsuspend_card(card)
      "bury" -> bury_card(card)
      "unbury" -> unbury_card(card)
      _ -> {:ok, card}
    end
  end

  @spec answer_card(Card.t(), Choices.t(), Integer.t()) ::
          {:ok, Card.t()} | {:error, Ecto.Changeset.t()}
  def answer_card(%Card{} = card, choice, time_answer) do
    integer_choice =
      case Integer.parse(to_string(choice)) do
        {c, _} -> c
        :error -> Choices.ok()
      end

    choice = Memoet.Cards.Choices.to_atom(integer_choice)
    scheduler = SRS.get_scheduler(card.user_id)

    srs_card =
      SRS.Card.from_ecto_card(card)
      |> SRS.Sm2.answer_card(scheduler, choice)

    ecto_card = Map.from_struct(SRS.Card.to_ecto_card(srs_card))
    log_card_answer(integer_choice, card, ecto_card, time_answer)
    update_new_today(card)

    card
    |> Card.srs_changeset(ecto_card)
    |> Repo.update()
  end

  defp update_new_today(card) do
    if card.card_type == CardTypes.new() do
      deck = Decks.get_deck!(card.deck_id)
      Decks.update_new(deck, %{"new_today" => deck.new_today - 1})
    end
  end

  defp log_card_answer(choice, card_before, card_after, time_answer) do
    time_answer = max(@min_time_answer, min(time_answer, @max_time_answer))

    attrs = %{
      "choice" => choice,
      "card_id" => card_before.id,
      "user_id" => card_before.user_id,
      "deck_id" => card_before.deck_id,
      "last_interval" => card_before.interval,
      "interval" => card_after.interval,
      "ease_factor" => card_after.ease_factor,
      "time_answer" => time_answer,
      "card_type" => card_after.card_type
    }

    result =
      %CardLog{}
      |> CardLog.changeset(attrs)
      |> Repo.insert()

    case result do
      {:error, changeset} -> Logger.error(changeset)
      {:ok, _} -> :ok
    end

    Decks.touch_deck_update_time(card_before.deck_id)
  end

  @spec next_intervals(Card.t()) :: map()
  def next_intervals(%Card{} = card) do
    scheduler = SRS.get_scheduler(card.user_id)

    srs_card = SRS.Card.from_ecto_card(card)

    [Choices.again(), Choices.hard(), Choices.ok(), Choices.easy()]
    |> Enum.map(fn choice ->
      {choice,
       SRS.Sm2.next_interval_string(srs_card, scheduler, Memoet.Cards.Choices.to_atom(choice))}
    end)
    |> Map.new()
  end

  @spec filter_where(map) :: Ecto.Query.DynamicExpr.t()
  defp filter_where(attrs) do
    Enum.reduce(attrs, dynamic(true), fn
      {"card_type", value}, dynamic ->
        dynamic([c], ^dynamic and c.card_type == ^value)

      {"card_queue", value}, dynamic ->
        dynamic([c], ^dynamic and c.card_queue == ^value)

      {"note_id", value}, dynamic ->
        dynamic([c], ^dynamic and c.note_id == ^value)

      {"deck_id", value}, dynamic ->
        dynamic([c], ^dynamic and c.deck_id == ^value)

      {_, _}, dynamic ->
        # Not a where parameter
        dynamic
    end)
  end
end
