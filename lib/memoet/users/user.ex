defmodule Memoet.Users.User do
  @moduledoc """
  User repo
  """
  import Ecto.Changeset

  use Ecto.Schema
  use Pow.Ecto.Schema

  use Pow.Extension.Ecto.Schema,
    extensions: [PowResetPassword, PowEmailConfirmation]

  alias Memoet.Accounts.{Account, Roles}
  alias Memoet.Str

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "users" do
    field(:email_confirmation_token, :string)
    field(:email_confirmed_at, :utc_datetime)
    field(:unconfirmed_email, :string)

    field(:api_token, :binary_id, null: false)

    field(:role, :string, default: Roles.member())
    belongs_to(:account, Account, type: :binary_id)

    pow_user_fields()

    timestamps()
  end

  def changeset(user_or_changeset, attrs) do
    user_or_changeset
    |> pow_changeset(attrs)
    |> cast(attrs, [:api_token, :account_id, :role])
    |> set_default_token()
    |> pow_extension_changeset(attrs)
    |> unique_constraint(:api_token)
  end

  def api_token_changeset(user_or_changeset, attrs) do
    user_or_changeset
    |> cast(attrs, [:api_token])
    |> validate_required([:api_token])
    |> unique_constraint(:api_token)
  end

  defp set_default_token(changeset) do
    api_token = get_field(changeset, :api_token)

    if StringUtil.blank?(api_token) do
      put_change(changeset, :api_token, Pow.UUID.generate())
    else
      changeset
    end
  end
end
