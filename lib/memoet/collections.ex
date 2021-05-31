defmodule Memoet.Collections do
  @moduledoc """
  Collection service
  """

  import Ecto.Query

  alias Memoet.Repo
  alias Memoet.Collections.Collection

  @spec get_today_collection(integer()) :: nil | Collection.t()
  def get_today_collection(user_id) do
    Collection
    |> where(user_id: ^user_id)
    |> Repo.one()
    |> Repo.preload(:decks)
    |> case do
      %Collection{} = collection ->
        collection

      nil ->
        create_today_collection(user_id)
    end
  end

  @spec update_today_collection(Collection.t(), map()) ::
          {:ok, Collection.t()} | {:error, Ecto.Changeset.t()}
  def update_today_collection(collection, params) do
    collection
    |> Collection.changeset(params)
    |> Repo.update()
  end

  defp create_today_collection(user_id) do
    %Collection{}
    |> Collection.changeset(%{user_id: user_id, name: "Today"})
    |> Repo.insert()
    |> case do
      {:ok, collection} -> %Collection{collection | decks: []}
      {:serror, _reason} -> nil
    end
  end
end
