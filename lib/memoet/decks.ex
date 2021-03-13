defmodule Memoet.Decks do

  import Ecto.Query

  alias Memoet.Repo
  alias Memoet.Decks.Deck

  @spec list_decks(binary(), map) :: [Deck.t()]
  def list_decks(user_id, _params) do
    Deck
    |> where(user_id: ^user_id)
    |> order_by(desc: :inserted_at)
    |> Repo.all()
  end

  @spec get_deck!(binary()) :: Deck.t()
  def get_deck!(id) do
    Deck
    |> Repo.get_by!(id: id)
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
    deck
    |> Deck.changeset(attrs)
    |> Repo.update()
  end
end
