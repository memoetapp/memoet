defmodule Memoet.Cards do
  @moduledoc """
  Card context
  """
  import Ecto.Query

  require Logger

  alias Memoet.Repo
  alias Memoet.Cards.{Card, CardLog, CardQueues, Choices}
  alias Memoet.Decks
  alias Memoet.SRS
  alias Memoet.Utils.TimestampUtil

  @limit 1
  # 1 sec
  @min_time_answer 1_000
  # 60 secs
  @max_time_answer 60_000

  def due_cards(params) do
    today = get_today(params)
    now = TimestampUtil.now()

    review_cards_query =
      from(c in Card,
        where:
          (c.card_queue == ^CardQueues.learn() and c.due < ^now) or
            (c.card_queue == ^CardQueues.review() and c.due <= ^today) or
            (c.card_queue == ^CardQueues.day_learn() and c.due <= ^today),
        order_by: fragment("RANDOM()")
      )

    new_cards_query =
      from(c in Card,
        where: c.card_queue == ^CardQueues.new(),
        order_by: fragment("RANDOM()")
      )

    cards = get_random_cards(review_cards_query, params)

    if length(cards) > 0 do
      cards
    else
      get_random_cards(new_cards_query, params)
    end
  end

  defp get_random_cards(query, params) do
    query
    |> where(^filter_where(params))
    |> limit(@limit)
    |> Repo.all()
    |> Repo.preload([:note])
  end

  defp get_today(params) do
    case params do
      %{today: today} -> today
      _ -> TimestampUtil.today()
    end
  end

  @spec list_cards(map) :: [Card.t()]
  def list_cards(params) do
    Card
    |> where(^filter_where(params))
    |> limit(@limit)
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

    card
    |> Card.srs_changeset(ecto_card)
    |> Repo.update()
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
