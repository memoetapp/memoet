defmodule Memoet.Repo.Migrations.AddCardLog do
  use Ecto.Migration

  def change do
    create table(:card_logs, primary_key: false) do
      add(:id, :binary_id, primary_key: true)

      add(:choice, :integer, null: false)
      add(:interval, :integer, null: false)
      add(:last_interval, :integer, null: false)
      add(:ease_factor, :integer, null: false)
      add(:time_answer, :integer, null: false)
      add(:card_type, :integer, null: false)

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
        :card_id,
        references(:cards,
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

    create(index(:card_logs, [:user_id]))
    create(index(:card_logs, [:card_id]))
    create(index(:card_logs, [:deck_id]))
  end
end
