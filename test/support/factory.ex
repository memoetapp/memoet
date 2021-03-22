defmodule Memoet.Factory do
  @moduledoc """
  Factory for test
  """

  use ExMachina.Ecto, repo: Memoet.Repo

  def account_factory(attrs) do
    account = %Memoet.Accounts.Account{
      name: sequence("some company_name"),
    }

    merge_attributes(account, attrs)
  end

  def user_factory(attrs) do
    user = %Memoet.Users.User{
      email: sequence(:email, &"email-#{&1}@example.com"),
      account: build(:account),
      api_token: Ecto.UUID.generate()
    }

    merge_attributes(user, attrs)
  end
end
