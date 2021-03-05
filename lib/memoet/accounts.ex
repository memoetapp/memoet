defmodule Memoet.Accounts do
  @moduledoc """
  Accounts context
  """

  alias Memoet.Repo
  alias Memoet.Accounts.Account

  @spec get_account!(binary()) :: Account.t()
  def get_account!(id) do
    Account
    |> Repo.get!(id)
    |> Repo.preload([:users])
  end

  @spec create_account(map()) :: {:ok, Account.t()} | {:error, Ecto.Changeset.t()}
  def create_account(attrs \\ %{}) do
    Account.changeset(%Account{}, attrs)
    |> Repo.insert()
  end

  @spec update_account(Account.t(), map()) :: {:ok, Account.t()} | {:error, Ecto.Changeset.t()}
  def update_account(%Account{} = account, attrs) do
    account
    |> Account.changeset(attrs)
    |> Repo.update()
  end
end
