defmodule Memoet.Repo.Migrations.ShuffleNotes do
  use Ecto.Migration

  def change do
    alter table(:decks) do
      add(:shuffled, :boolean, null: false, default: false)
    end
  end
end
