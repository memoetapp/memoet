defmodule Memoet.Cards do
  @moduledoc """
  Card context
  """
  import Ecto.Query

  alias Memoet.Repo
  alias Memoet.Cards.{Card, CardQueues}
  alias Memoet.SRS
  alias Memoet.Users
  alias Memoet.Utils.TimestampUtil

  @limit 1

  def due_cards(user_id, params) do
    srs_config = Users.get_srs_config(user_id)

    collapse_time = srs_config.learn_ahead_time * 60

    today = get_today(params)
    now = TimestampUtil.now() + collapse_time

    from(c in Card,
      where:
        c.card_queue == ^CardQueues.new() or
          (c.card_queue == ^CardQueues.learn() and c.due < ^now) or
          (c.card_queue == ^CardQueues.review() and c.due <= ^today) or
          (c.card_queue == ^CardQueues.day_learn() and c.due <= ^today),
      order_by: fragment("RANDOM()")
    )
    |> filter_by_deck(params)
    |> where(user_id: ^user_id)
    |> limit(@limit)
    |> Repo.all()
    |> Repo.preload([:note])
  end

  defp filter_by_deck(query, params) do
    case params do
      %{deck_id: deck_id} ->
        query
        |> where(deck_id: ^deck_id)

      _ ->
        query
    end
  end

  defp get_today(params) do
    case params do
      %{today: today} -> today
      _ -> TimestampUtil.today()
    end
  end

  @spec list_cards(binary(), map) :: [Card.t()]
  def list_cards(user_id, params) do
    Card
    |> where(^filter_where(params))
    |> where(user_id: ^user_id)
    |> limit(@limit)
    |> Repo.all()
    |> Repo.preload([:note])
  end

  @spec stats(binary(), map) :: map()
  def stats(user_id, _params \\ %{}) do
    stats =
      from(c in Card,
        group_by: c.card_queue,
        where: c.user_id == ^user_id,
        select: {c.card_queue, count(c.id)}
      )
      |> Repo.all()

    stats =
      stats
      |> Enum.map(fn {q, c} -> {CardQueues.to_atom(q), c} end)
      |> Enum.into(%{})

    total =
      stats
      |> Enum.map(fn {_q, c} -> c end)
      |> Enum.sum()

    stats
    |> Map.merge(%{total: total})
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

  @spec answer_card(Card.t(), integer()) :: {:ok, Card.t()} | {:error, Ecto.Changeset.t()}
  def answer_card(%Card{} = card, choice) do
    choice = Memoet.Cards.Choices.to_atom(choice)

    scheduler = SRS.get_scheduler(card.user_id)

    srs_card =
      SRS.Card.from_ecto_card(card)
      |> SRS.Sm2.answer_card(scheduler, choice)

    ecto_card = Map.from_struct(SRS.Card.to_ecto_card(srs_card))

    card
    |> Card.srs_changeset(ecto_card)
    |> Repo.update()
  end

  @spec filter_where(map) :: Ecto.Query.DynamicExpr.t()
  defp filter_where(attrs) do
    Enum.reduce(attrs, dynamic(true), fn
      {"card_type", value}, dynamic ->
        dynamic([p], ^dynamic and p.card_type == ^value)

      {"card_queue", value}, dynamic ->
        dynamic([p], ^dynamic and p.card_queue == ^value)

      {_, _}, dynamic ->
        # Not a where parameter
        dynamic
    end)
  end
end
