defmodule Memoet.Factory do
  @moduledoc """
  Factory for test
  """

  use ExMachina.Ecto, repo: Memoet.Repo

  def account_factory(attrs) do
    account = %Memoet.Accounts.Account{
      name: sequence("some company_name")
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

  def deck_factory(%{user: user} = attrs) do
    deck = %Memoet.Decks.Deck{
      name: sequence("name"),
      user: user
    }

    merge_attributes(deck, attrs)
  end

  def note_factory(%{deck: deck} = attrs) do
    note = %Memoet.Notes.Note{
      title: sequence("title"),
      content: "",
      deck: deck,
      user: deck.user
    }

    merge_attributes(note, attrs)
  end
end
