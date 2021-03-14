defmodule Memoet.SRS.Card do
  defstruct card_type: :new,
            card_queue: :new,
            due: 0,
            interval: 0,
            ease_factor: 0,
            reps: 0,
            lapses: 0,
            remaining_steps: 0

  def from_ecto_card(ecto_card) do
    card_map = Map.from_struct(ecto_card)

    card_map =
      card_map
      |> Map.merge(%{
        card_type: Memoet.Cards.CardTypes.to_atom(card_map.card_type),
        card_queue: Memoet.Cards.CardQueues.to_atom(card_map.card_queue)
      })

    struct(Memoet.SRS.Card, card_map)
  end

  def to_ecto_card(sm2_card) do
    card_map = Map.from_struct(sm2_card)

    card_map =
      card_map
      |> Map.merge(%{
        card_type: Memoet.Cards.CardTypes.from_atom(card_map.card_type),
        card_queue: Memoet.Cards.CardQueues.from_atom(card_map.card_queue)
      })

    struct(Memoet.Cards.Card, card_map)
  end
end
