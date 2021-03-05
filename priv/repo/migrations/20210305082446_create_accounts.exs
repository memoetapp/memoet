defmodule Memoet.Repo.Migrations.CreateAccounts do
  use Ecto.Migration

  def change do
    create table(:accounts, primary_key: false) do
      add(:id, :binary_id, primary_key: true)

      add(:name, :string, null: false)
      add(:plan, :string, null: false)

      timestamps()
    end
  end
end
