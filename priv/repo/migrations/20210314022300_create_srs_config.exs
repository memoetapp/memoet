defmodule Memoet.Repo.Migrations.CreateSrsConfig do
  use Ecto.Migration

  def change do
    create table(:srs_config, primary_key: false) do
      add(:id, :binary_id, primary_key: true)

      add(:learn_ahead_time, :integer, null: false)

      add(:learn_steps, {:array, :float}, default: [], null: false)
      add(:relearn_steps, {:array, :float}, default: [], null: false)

      add(:initial_ease, :integer, null: false)

      add(:easy_multiplier, :float, null: false)
      add(:hard_multiplier, :float, null: false)
      add(:lapse_multiplier, :float, null: false)
      add(:interval_multiplier, :float, null: false)

      add(:maximum_review_interval, :integer, null: false)
      add(:minimum_review_interval, :integer, null: false)

      add(:graduating_interval_good, :integer, null: false)
      add(:graduating_interval_easy, :integer, null: false)

      add(:leech_threshold, :integer, null: false)

      add(:time_zone, :string, null: false, default: "Etc/Greenwich")

      add(
        :user_id,
        references(:users,
          column: :id,
          on_delete: :delete_all,
          type: :binary_id
        ),
        null: false
      )

      timestamps()
    end

    create(index(:srs_config, [:user_id]))
  end
end
