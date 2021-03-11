defmodule Memoet.Repo.Migrations.CreateNotes do
  use Ecto.Migration

  def change do
    create table(:notes, primary_key: false) do
      add(:id, :binary_id, primary_key: true)

      add(:order, :float, null: false)

      add(:title, :string, null: false)
      add(:content, :text, null: false)

      add(:trash, :boolean, null: false, default: false)

      add(
        :user_id,
        references(:users,
          column: :id,
          on_delete: :delete_all,
          type: :binary_id
        ),
        null: false
      )

      add(
        :deck_id,
        references(:decks,
          column: :id,
          on_delete: :delete_all,
          type: :binary_id
        ),
        null: false
      )

      timestamps()
    end

    create(index(:notes, [:user_id]))
  end
end
