defmodule Memoet.Accounts.Account do
  @moduledoc """
  An account has one or many users
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Memoet.{Accounts.Plans, Users.User}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "accounts" do
    field(:name, :string)
    field(:plan, :string, default: Plans.free())

    has_many(:users, User)

    timestamps()
  end

  def changeset(account, attrs) do
    account
    |> cast(attrs, [:name])
    |> validate_required([:name])
  end
end
