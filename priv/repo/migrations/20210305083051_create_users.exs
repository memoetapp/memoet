defmodule Memoet.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users, primary_key: false) do
      add(:id, :binary_id, primary_key: true)

      add :email, :string, null: false
      add :password_hash, :string

      add :email_confirmation_token, :string
      add :email_confirmed_at, :utc_datetime
      add :unconfirmed_email, :string

      add :role, :string, null: false
      add :account_id, references(:accounts, type: :binary_id), null: false

      timestamps()
    end

    create unique_index(:users, [:email])
  end
end
