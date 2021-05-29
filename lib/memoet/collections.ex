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
    |> case do
      %Collection{} = collection ->
        collection

      nil ->
        create_today_collection(user_id)
    end
  end

  @spec update_today_collection(integer(), map()) :: {:ok, SrsConfig.t()} | {:error, Ecto.Changeset.t()}
  def update_today_collection(user_id, params) do
    get_today_collection(user_id)
    |> Collection.changeset(params)
    |> Repo.update()
  end

  defp create_today_collection(user_id) do
    %Collection{}
    |> Collection.changeset(%{user_id: user_id, name: "Today"})
    |> Repo.insert()
    |> case do
      {:ok, collection} -> collection
      {:serror, _reason} -> nil
    end
  end
end
