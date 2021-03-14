defmodule Memoet.Repo.Migrations.CreateDecks do
  use Ecto.Migration

  def change do
    create table(:decks, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :name, :string, null: false
      add :public, :boolean, null: false, default: false

      add :trash, :boolean, null: false, default: false

      add :user_id,
          references(
            :users,
            on_delete: :delete_all,
            type: :binary_id
          ),
          null: false

      add :source_id,
          references(
            :decks,
            on_delete: :nilify_all,
            type: :binary_id
          ),
          null: true

      timestamps()
    end

    create index(:decks, [:user_id])
    create index(:decks, [:source_id])
  end
end
