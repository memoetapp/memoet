defmodule Memoet.Users.SrsConfig do
  @moduledoc """
  SRS config repo
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Memoet.Users.User

  @srs_fields [
    :learn_ahead_time,
    :timezone,
    :learn_steps,
    :relearn_steps,
    :initial_ease,
    :easy_multiplier,
    :hard_multiplier,
    :lapse_multiplier,
    :interval_multiplier,
    :maximum_review_interval,
    :minimum_review_interval,
    :graduating_interval_good,
    :graduating_interval_easy
    # TODO: Support leech feature
    # :leech_threshold
  ]
  @required_fields [:user_id]

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "srs_config" do
    field(:learn_ahead_time, :integer, default: 20)

    field(:learn_steps, {:array, :float}, default: [1.0, 10.0])
    field(:relearn_steps, {:array, :float}, default: [10.0])

    field(:initial_ease, :integer, default: 2_500)

    field(:easy_multiplier, :float, default: 1.3)
    field(:hard_multiplier, :float, default: 1.2)
    field(:lapse_multiplier, :float, default: 0.0)
    field(:interval_multiplier, :float, default: 1.0)

    field(:maximum_review_interval, :integer, default: 36_500)
    field(:minimum_review_interval, :integer, default: 1)

    field(:graduating_interval_good, :integer, default: 1)
    field(:graduating_interval_easy, :integer, default: 4)

    # Should be 7 or 8 times, we set 1_000_000 here to not support it for now
    field(:leech_threshold, :integer, default: 1_000_000)

    field(:timezone, :string, default: "Etc/Greenwich")

    belongs_to(:user, User, foreign_key: :user_id, references: :id, type: :binary_id)

    timestamps()
  end

  def changeset(srs_config, attrs) do
    attrs = cast_text_to_array(attrs)

    srs_config
    |> cast(attrs, @srs_fields ++ @required_fields)
    |> validate_required(@required_fields)
  end

  def cast_text_to_array(params) do
    case params do
      %{
        "learn_steps" => learn_steps,
        "relearn_steps" => relearn_steps
      } ->
        params
        |> Map.merge(%{
          "learn_steps" => text_to_array(learn_steps),
          "relearn_steps" => text_to_array(relearn_steps)
        })

      _ ->
        params
    end
  end

  defp text_to_array(field) do
    if is_binary(field) do
      String.split(field, " ")
    else
      field
    end
  end
end
