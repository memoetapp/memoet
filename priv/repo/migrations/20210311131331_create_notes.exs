defmodule Memoet.Repo.Migrations.CreateNotes do
  use Ecto.Migration

  def change do
    create table(:notes, primary_key: false) do
      add(:id, :binary_id, primary_key: true)

      add(:title, :text, null: false)
      add(:image, :text, null: true)
      add(:content, :text, null: false)

      add(:type, :string, null: false)
      add(:options, {:array, :map}, null: false, default: [])

      add(:hint, :text)

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
    create(index(:notes, [:title]))
  end
end
