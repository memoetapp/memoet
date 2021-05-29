defmodule Memoet.Repo.Migrations.CreateCollections do
  use Ecto.Migration

  def change do
    # Collections
    create table(:collections, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:name, :string, null: false, default: "Today")
      add(:user_id, references(:users, type: :binary_id, on_delete: :delete_all))

      timestamps()
    end

    create(index(:collections, [:user_id]))

    # Decks collections
    create table(:decks_collections, primary_key: false) do
      add(:id, :binary_id, primary_key: true)

      add(:deck_id, references(:decks, type: :binary_id, on_delete: :delete_all))
      add(:collection_id, references(:collections, type: :binary_id, on_delete: :delete_all))
      add(:user_id, references(:users, type: :binary_id, on_delete: :delete_all))

      timestamps()
    end

    create(unique_index(:decks_collections, [:user_id, :collection_id, :deck_id]))
    create(index(:decks_collections, [:user_id]))
    create(index(:decks_collections, [:deck_id]))
    create(index(:decks_collections, [:collection_id]))
  end
end
